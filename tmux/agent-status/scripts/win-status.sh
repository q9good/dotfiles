#!/usr/bin/env bash
# win-status.sh — compact per-window status for tmux window-status-format
# Args: session_name window_index
# Output: " ⚙Bash 2m" / " ⚡ 45s" / " ⏸" / " ✓" / " ▶cmd"  (or empty)

sess="$1"
widx="$2"
[ -z "$sess" ] || [ -z "$widx" ] && exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/state.sh"
source "$SCRIPT_DIR/lib/format-status.sh"

now=$(date +%s)
claude_out=""
shell_out=""

while IFS= read -r pane_id; do
    [ -z "$claude_out" ] && claude_out=$(fmt_pane_claude "$sess" "$pane_id")
    [ -z "$shell_out" ]  && shell_out=$(fmt_pane_shell  "$sess" "$pane_id")
    [ -n "$claude_out" ] && [ -n "$shell_out" ] && break
done < <(tmux list-panes -t "${sess}:${widx}" -F '#{pane_id}' 2>/dev/null)

out="${claude_out}${claude_out:+${shell_out:+ }}${shell_out}"
[ -n "$out" ] && printf ' %s' "$out"
