#!/usr/bin/env bash
# status-line.sh — renders agent + shell status for tmux status-right
# Output: "⚡2 ✓1 ⏱[build]" (or empty when nothing active)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/state.sh"

SHELL_TTL=30  # seconds to keep shell notify visible
now=$(date +%s)

working=0; waiting=0; done_count=0
shell_items=()

# Count Claude agent sessions
while IFS= read -r session; do
    [ -z "$session" ] && continue
    sf="$SESSION_DIR/${session}.status"
    [ -f "$sf" ] || continue
    case "$(cat "$sf" 2>/dev/null)" in
        working) (( working++ )) ;;
        wait)    (( waiting++ )) ;;
        done)    (( done_count++ )) ;;
    esac
done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null)

# Collect recent shell long-command completions
for nf in "$SHELL_DIR/"*.notify; do
    [ -f "$nf" ] || continue
    IFS=':' read -r elapsed win_name finish_ts < "$nf"
    age=$(( now - finish_ts ))
    if (( age > SHELL_TTL )); then
        rm -f "$nf"
    else
        shell_items+=("⏱[${win_name}]")
    fi
done

parts=()
(( working > 0 ))    && parts+=("⚡${working}")
(( waiting > 0 ))    && parts+=("⏸${waiting}")
(( done_count > 0 )) && parts+=("✓${done_count}")
for item in "${shell_items[@]}"; do parts+=("$item"); done

(( ${#parts[@]} > 0 )) && printf '%s' "${parts[*]}"
