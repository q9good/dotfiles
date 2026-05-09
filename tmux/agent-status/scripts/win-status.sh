#!/usr/bin/env bash
# win-status.sh — compact per-window status for tmux window-status-format
# Args: session_name window_index
# Output: " ⚙Bash" / " ⚡" / " ⏸" / " ✓" / " ▶cmd"  (or empty)

sess="$1"
widx="$2"
[ -z "$sess" ] || [ -z "$widx" ] && exit 0

PANE_DIR="$HOME/.cache/agent-status/panes"
SHELL_DIR="$HOME/.cache/agent-status/shell"

claude_out=""
shell_out=""
now=$(date +%s)

while IFS= read -r pane_id; do
    pf="$PANE_DIR/${sess}_${pane_id}.status"
    [ -f "$pf" ] || continue
    ps=$(cat "$pf" 2>/dev/null)

    if [ -z "$claude_out" ]; then
        case "$ps" in
            working)
                tool=$(cat "$PANE_DIR/${sess}_${pane_id}.tool" 2>/dev/null)
                claude_out="${tool:+⚙${tool}}"
                claude_out="${claude_out:-⚡}"
                ;;
            wait) claude_out="⏸" ;;
            done) claude_out="✓" ;;
        esac
    fi

    if [ -z "$shell_out" ]; then
        rf="$SHELL_DIR/${sess}_${pane_id}.running"
        if [ -f "$rf" ]; then
            IFS=':' read -r cmd start_ts < "$rf"
            age=$(( now - start_ts ))
            (( age >= 3 )) && shell_out="▶${cmd}"
        fi
    fi

    [ -n "$claude_out" ] && [ -n "$shell_out" ] && break
done < <(tmux list-panes -t "${sess}:${widx}" -F '#{pane_id}' 2>/dev/null)

out="${claude_out}${claude_out:+${shell_out:+ }}${shell_out}"
[ -n "$out" ] && printf ' %s' "$out"
