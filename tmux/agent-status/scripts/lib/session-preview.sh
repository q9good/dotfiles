#!/usr/bin/env bash
# session-preview.sh — fzf preview pane showing live session/window details
# Called by switcher.sh with the selected target: "session" or "session:winidx"

TARGET="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/state.sh"
source "$SCRIPT_DIR/format-status.sh"

now=$(date +%s)

# Extract session (and optional window) from target
if [[ "$TARGET" == *:* ]]; then
    focus_sess="${TARGET%%:*}"
    focus_win="${TARGET##*:}"
else
    focus_sess="$TARGET"
    focus_win=""
fi

# Colors (ANSI, work inside fzf preview)
R=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
GN=$'\033[32m'
YL=$'\033[33m'
RD=$'\033[31m'
BL=$'\033[34m'
CY=$'\033[36m'

# Colorize a status token from format-status.sh
colorize() {
    local s="$1"
    case "$s" in
        ⚙*)           printf '%s%s%s' "$YL" "$s" "$R" ;;
        ⚡*)           printf '%s%s%s' "$YL" "$s" "$R" ;;
        ⏸*)           printf '%s%s%s' "$RD" "$s" "$R" ;;
        ✓*)            printf '%s%s%s' "$GN" "$s" "$R" ;;
        *▶*)           printf '%s%s%s' "$BL" "$s" "$R" ;;  # zsh▶make or ▶cmd
        bash|zsh|fish) printf '%s%s%s' "$DIM" "$s" "$R" ;;  # idle shell
        *)             printf '%s' "$s" ;;
    esac
}

while IFS= read -r sess; do
    [ -z "$sess" ] && continue

    sf="$SESSION_DIR/${sess}.status"
    sess_status=$(cat "$sf" 2>/dev/null)
    case "$sess_status" in
        working) s_icon="${YL}⚡${R}" ;;
        done)    s_icon="${GN}✓${R}" ;;
        wait)    s_icon="${RD}⏸${R}" ;;
        *)       s_icon="  " ;;
    esac
    printf '%s %s%s%s\n' "$s_icon" "$BOLD" "$sess" "$R"

    while IFS=$'\t' read -r widx wname; do
        [ -z "$widx" ] && continue

        win_parts=()
        while IFS=$'\t' read -r pane_id pane_cmd; do
            local cs; cs=$(fmt_pane_claude "$sess" "$pane_id")
            [ -n "$cs" ] && win_parts+=("$(colorize "$cs")")
            local ss; ss=$(fmt_pane_shell "$sess" "$pane_id" "$pane_cmd")
            [ -n "$ss" ] && win_parts+=("$(colorize "$ss")")
        done < <(tmux list-panes -t "${sess}:${widx}" -F "#{pane_id}	#{pane_current_command}" 2>/dev/null)

        if [ "${#win_parts[@]}" -gt 0 ]; then
            status_str=$(IFS=' '; printf '%s' "${win_parts[*]}")
            printf '  %s  %s  %s\n' "$widx" "$wname" "$status_str"
        else
            printf '  %s  %s\n' "$widx" "$wname"
        fi

    done < <(tmux list-windows -t "$sess" -F "#{window_index}$'\t'#{window_name}" 2>/dev/null)

    printf '\n'
done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null)
