#!/usr/bin/env bash
# hook.sh — Claude Code hook handler for agent-status

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../scripts/lib/state.sh"

input=""
if [[ ! -t 0 ]]; then
    input=$(cat 2>/dev/null || true)
fi

json_val()  { printf '%s' "$1" | grep -o "\"$2\":\"[^\"]*\"" | head -1 | cut -d'"' -f4; }
json_bool() { printf '%s' "$1" | grep -q "\"$2\":true"; }

hook_type=$(json_val "$input" "hook_event_name")
[ -z "$hook_type" ] && hook_type="${1:-}"

[ -z "${TMUX:-}" ] && exit 0
TMUX_SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null) || exit 0
PANE_ID="${TMUX_PANE:-}"

set_pane_status() {
    local status="$1"
    [ -n "$PANE_ID" ] || return
    printf '%s\n' "$status" > "$PANE_DIR/${TMUX_SESSION}_${PANE_ID}.status"
    if [ "$status" = "working" ]; then
        # Record start time only once (don't reset on each tool call)
        local ts_file="$PANE_DIR/${TMUX_SESSION}_${PANE_ID}.start_ts"
        [ -f "$ts_file" ] || printf '%s\n' "$(date +%s)" > "$ts_file"
    else
        rm -f "$PANE_DIR/${TMUX_SESSION}_${PANE_ID}.tool" \
              "$PANE_DIR/${TMUX_SESSION}_${PANE_ID}.start_ts" 2>/dev/null
    fi
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
        # Store tool name so switcher can show ⚙Bash, ⚙Edit etc.
        tool=$(json_val "$input" "tool_name")
        [ -n "$tool" ] && [ -n "$PANE_ID" ] && \
            printf '%s\n' "$tool" > "$PANE_DIR/${TMUX_SESSION}_${PANE_ID}.tool"
        aggregate_session
        ;;

    PostToolUse)
        # Tool finished; Claude is generating text again — clear tool name so
        # status shows ⚡ (working) instead of the stale tool name.
        [ -n "$PANE_ID" ] && \
            rm -f "$PANE_DIR/${TMUX_SESSION}_${PANE_ID}.tool" 2>/dev/null
        ;;

    Stop)
        json_bool "$input" "stop_hook_active" && exit 0
        set_pane_status "done"
        aggregate_session
        ( printf '\a' > /dev/tty ) 2>/dev/null || printf '\a'
        "$SCRIPT_DIR/../scripts/popup.sh" --state=done --pane="$PANE_ID" &
        ;;

    Notification)
        set_pane_status "wait"
        aggregate_session
        ( printf '\a' > /dev/tty ) 2>/dev/null || printf '\a'
        msg=$(json_val "$input" "message")
        label="APPROVE?"
        [[ "$msg" =~ to\ use\ (.+) ]] && label="${BASH_REMATCH[1]}?"
        "$SCRIPT_DIR/../scripts/popup.sh" --state=permission --label="$label" --pane="$PANE_ID" &
        ;;
esac

exit 0
