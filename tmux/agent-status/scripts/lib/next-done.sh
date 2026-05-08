#!/usr/bin/env bash
# Jump to the next tmux session whose Claude agent status is "done"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/state.sh"

current=$(tmux display-message -p '#{session_name}' 2>/dev/null)

while IFS= read -r sess; do
    [ "$sess" = "$current" ] && continue
    sf="$SESSION_DIR/${sess}.status"
    [ -f "$sf" ] || continue
    if [ "$(cat "$sf" 2>/dev/null)" = "done" ]; then
        tmux switch-client -t "$sess"
        exit 0
    fi
done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null)

tmux display-message "No done sessions"
