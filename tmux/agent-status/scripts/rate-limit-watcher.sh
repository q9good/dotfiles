#!/usr/bin/env bash
# Conservatively resume tmux panes stopped by an explicit API rate-limit error.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/state.sh"

POLL_SECONDS="${TMUX_RATE_LIMIT_POLL_SECONDS:-5}"
WAIT_SECONDS="${TMUX_RATE_LIMIT_WAIT_SECONDS:-75}"
WINDOW_SECONDS="${TMUX_RATE_LIMIT_WINDOW_SECONDS:-1800}"
MAX_RETRIES="${TMUX_RATE_LIMIT_MAX_RETRIES:-2}"
RECOVERY_DIR="$STATE_DIR/rate-limit-recovery"
WATCHER_DIR="$RECOVERY_DIR/watcher"

case "$WAIT_SECONDS" in *[!0-9]*|"") WAIT_SECONDS=75 ;; esac
case "$WINDOW_SECONDS" in *[!0-9]*|"") WINDOW_SECONDS=1800 ;; esac
case "$MAX_RETRIES" in *[!0-9]*|"") MAX_RETRIES=2 ;; esac
[ "$WAIT_SECONDS" -lt 60 ] && WAIT_SECONDS=60
[ "$WINDOW_SECONDS" -lt 300 ] && WINDOW_SECONDS=300
[ "$MAX_RETRIES" -lt 1 ] && MAX_RETRIES=1
[ "$MAX_RETRIES" -gt 3 ] && MAX_RETRIES=3

mkdir -p "$RECOVERY_DIR"

log() {
    printf '%s rate-limit-watcher: %s\n' \
        "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$*" \
        >> "$RECOVERY_DIR/watcher.log"
}

hash_text() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum | awk '{print $1}'
    else
        shasum -a 256 | awk '{print $1}'
    fi
}

capture_tail() {
    local pane="$1"
    tmux capture-pane -p -t "$pane" -S -80 2>/dev/null         | awk 'NF { lines[++n]=$0 } END { start=n-15; if (start<1) start=1; for (i=start;i<=n;i++) print lines[i] }'
}

is_explicit_rate_limit() {
    grep -Eiq 'rate[ -]?limit exceeded|too many requests|http([[:space:]-]+status)?[[:space:]:-]*429|status[[:space:]]+code[[:space:]:-]*429|error[[:space:]]+code[[:space:]:-]*429'
}

safe_pane_id() {
    printf '%s' "$1" | tr -c 'A-Za-z0-9_.-' '_'
}

claim_retry() {
    local pane="$1" signature="$2" now cutoff safe state pending tmp count
    now=$(date +%s)
    cutoff=$((now - WINDOW_SECONDS))
    safe=$(safe_pane_id "$pane")
    state="$RECOVERY_DIR/$safe.attempts"
    pending="$RECOVERY_DIR/$safe.pending"

    mkdir "$pending" 2>/dev/null || return 1
    printf '%s\n' "$signature" > "$pending/signature"

    tmp="$state.tmp.$$"
    if [ -f "$state" ]; then
        awk -v cutoff="$cutoff" '$1 >= cutoff { print $1 }' "$state" > "$tmp"
    else
        : > "$tmp"
    fi
    count=$(wc -l < "$tmp" | tr -d ' ')
    if [ "$count" -ge "$MAX_RETRIES" ]; then
        mv "$tmp" "$state"
        rm -rf "$pending"
        log "$pane retry cap reached ($MAX_RETRIES/$WINDOW_SECONDS seconds)"
        return 1
    fi
    printf '%s\n' "$now" >> "$tmp"
    mv "$tmp" "$state"
    printf '%s\n' "$((count + 1))"
}

clear_pending() {
    local pane="$1" safe
    safe=$(safe_pane_id "$pane")
    rm -rf "$RECOVERY_DIR/$safe.pending"
}

notify_user() {
    local message="$1"
    if command -v terminal-notifier >/dev/null 2>&1; then
        terminal-notifier -title "tmux rate-limit recovery" -message "$message" >/dev/null 2>&1 || true
    fi
    printf '\a' >/dev/tty 2>/dev/null || true
}

retry_after_delay() {
    local pane="$1" signature="$2" attempt="$3" delay tail current_signature
    delay=$((WAIT_SECONDS * (2 ** (attempt - 1))))
    log "$pane explicit rate limit detected; retry $attempt/$MAX_RETRIES in ${delay}s"
    sleep "$delay"

    if ! tmux display-message -p -t "$pane" '#{pane_dead}' >/dev/null 2>&1; then
        log "$pane disappeared; cancelling retry"
        clear_pending "$pane"
        return
    fi
    if [ "$(tmux display-message -p -t "$pane" '#{pane_dead}' 2>/dev/null)" = "1" ]; then
        log "$pane is dead; cancelling retry"
        clear_pending "$pane"
        return
    fi

    tail=$(capture_tail "$pane")
    if ! printf '%s\n' "$tail" | is_explicit_rate_limit; then
        log "$pane limit error is no longer in the terminal tail; cancelling retry"
        clear_pending "$pane"
        return
    fi
    current_signature=$(printf '%s' "$tail" | hash_text)
    if [ "$current_signature" != "$signature" ]; then
        log "$pane output changed; cancelling retry"
        clear_pending "$pane"
        return
    fi

    tmux send-keys -t "$pane" -l -- "go on"
    tmux send-keys -t "$pane" Enter
    log "$pane sent go on after ${delay}s cooldown"
    notify_user "$pane resumed after a rate-limit cooldown"
    clear_pending "$pane"
}

start_watcher() {
    if mkdir "$WATCHER_DIR" 2>/dev/null; then
        printf '%s\n' "$$" > "$WATCHER_DIR/pid"
    else
        if [ -f "$WATCHER_DIR/pid" ]; then
            old_pid=$(cat "$WATCHER_DIR/pid" 2>/dev/null || true)
            if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
                exit 0
            fi
        fi
        rm -rf "$WATCHER_DIR"
        mkdir "$WATCHER_DIR" 2>/dev/null || exit 0
        printf '%s\n' "$$" > "$WATCHER_DIR/pid"
    fi
    trap 'rm -rf "$WATCHER_DIR"' EXIT INT TERM HUP

    while tmux list-sessions >/dev/null 2>&1; do
        tmux list-panes -a -F '#{pane_id}\t#{pane_dead}' 2>/dev/null         | while IFS=$'\t' read -r pane dead; do
            [ -n "$pane" ] || continue
            [ "$dead" = "0" ] || continue
            tail=$(capture_tail "$pane")
            printf '%s\n' "$tail" | is_explicit_rate_limit || continue
            signature=$(printf '%s' "$tail" | hash_text)
            attempt=$(claim_retry "$pane" "$signature") || continue
            retry_after_delay "$pane" "$signature" "$attempt" &
        done
        sleep "$POLL_SECONDS"
    done
}

start_watcher
