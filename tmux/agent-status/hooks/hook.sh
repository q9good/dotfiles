#!/usr/bin/env bash
# hook.sh — Claude Code hook handler for agent-status
#
# Wired into ~/.claude/settings.json for:
#   UserPromptSubmit, PreToolUse, Stop, Notification
#
# Updates per-pane + session status files, and triggers popup on Stop/Notification.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../scripts/lib/state.sh"

# Read JSON from stdin (Claude Code pipes hook data here)
input=""
if [[ ! -t 0 ]]; then
    input=$(cat 2>/dev/null || true)
fi

# Parse hook type from JSON; fall back to $1 for manual/test invocations
json_val() { printf '%s' "$1" | grep -o "\"$2\":\"[^\"]*\"" | head -1 | cut -d'"' -f4; }
json_bool() { printf '%s' "$1" | grep -q "\"$2\":true"; }

hook_type=$(json_val "$input" "hook_event_name")
[ -z "$hook_type" ] && hook_type="${1:-}"

# Must be running inside tmux
[ -z "${TMUX:-}" ] && exit 0

TMUX_SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null) || exit 0
PANE_ID="${TMUX_PANE:-}"

set_pane_status() {
    local status="$1"
    [ -n "$PANE_ID" ] || return
    printf '%s\n' "$status" > "$PANE_DIR/${TMUX_SESSION}_${PANE_ID}.status"
}

aggregate_session() {
    local session_status="done"
    local f
    for f in "$PANE_DIR/${TMUX_SESSION}_"*.status; do
        [ -f "$f" ] || continue
        case "$(cat "$f" 2>/dev/null)" in
            working) session_status="working"; break ;;
            wait)    [ "$session_status" != "working" ] && session_status="wait" ;;
        esac
    done
    printf '%s\n' "$session_status" > "$SESSION_DIR/${TMUX_SESSION}.status"
}

case "$hook_type" in
    UserPromptSubmit)
        set_pane_status "working"
        aggregate_session
        ;;

    PreToolUse)
        set_pane_status "working"
        aggregate_session
        ;;

    Stop)
        # Prevent hook loop (Claude Code sets stop_hook_active=true when re-entering)
        json_bool "$input" "stop_hook_active" && exit 0
        set_pane_status "done"
        aggregate_session
        ( printf '\a' > /dev/tty ) 2>/dev/null || printf '\a'
        "$SCRIPT_DIR/../scripts/popup.sh" --state=done --pane="$PANE_ID" &
        ;;

    Notification)
        set_pane_status "done"
        aggregate_session
        ( printf '\a' > /dev/tty ) 2>/dev/null || printf '\a'
        # Extract tool name: "Permission to use Bash" → "Bash?"
        msg=$(json_val "$input" "message")
        label="APPROVE?"
        if [[ "$msg" =~ to\ use\ (.+) ]]; then
            label="${BASH_REMATCH[1]}?"
        fi
        "$SCRIPT_DIR/../scripts/popup.sh" --state=permission --label="$label" --pane="$PANE_ID" &
        ;;
esac

exit 0
