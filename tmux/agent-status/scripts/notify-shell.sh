#!/usr/bin/env bash
# notify-shell.sh — called from common.sh / common.fish when a long command finishes
# Usage: notify-shell.sh <elapsed_seconds>

ELAPSED="${1:-0}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/state.sh"

# Bell (works in all environments)
printf '\a' > /dev/tty 2>/dev/null || printf '\a'

[ -z "${TMUX:-}" ] && exit 0

WIN_NAME=$(tmux display-message -p '#W' 2>/dev/null)
WIN=$(tmux display-message -p '#I:#W' 2>/dev/null)
SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null)
PANE="${TMUX_PANE:-}"

# Write notify file for status bar (auto-expires in status-line.sh)
if [ -n "$SESSION" ] && [ -n "$PANE" ]; then
    printf '%s:%s:%s\n' "$ELAPSED" "$WIN_NAME" "$(date +%s)" \
        > "$SHELL_DIR/${SESSION}_${PANE}.notify"
fi

# Show popup (background so shell returns immediately)
"$SCRIPT_DIR/popup.sh" \
    --state=shell \
    --label="${WIN_NAME} ${ELAPSED}s" \
    --pane="$PANE" &

exit 0
