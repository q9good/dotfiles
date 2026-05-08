#!/usr/bin/env bash
# switcher.sh — fzf session/window picker with agent status indicators
#
# Layout:
#   ⚡  main ◀
#       1  nvim
#       2  build  ⚡
#   ✓  work
#       1  claude  ✓
#
# Enter on a session line  → switch to that session (its active window)
# Enter on a window line   → switch to that session:window

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/state.sh"

TAB=$'\t'

current_session=$(tmux display-message -p '#{session_name}' 2>/dev/null)
current_window=$(tmux display-message -p '#{window_index}' 2>/dev/null)

# Each entry: "DISPLAY${TAB}TARGET"
#   TARGET = "session"          → switch to session's active window
#   TARGET = "session:winidx"   → switch directly to that window
lines=()

while IFS= read -r sess; do
    [ -z "$sess" ] && continue

    # Session-level agent status icon
    sf="$SESSION_DIR/${sess}.status"
    icon="   "
    if [ -f "$sf" ]; then
        case "$(cat "$sf" 2>/dev/null)" in
            working) icon="⚡ " ;;
            done)    icon="✓  " ;;
            wait)    icon="⏸ " ;;
        esac
    fi

    marker=""
    [ "$sess" = "$current_session" ] && marker=" ◀"

    lines+=("${icon} ${sess}${marker}${TAB}${sess}")

    # Windows under this session
    while IFS=$'\t' read -r widx wname; do
        [ -z "$widx" ] && continue

        # Per-window status: aggregate pane status files for this window
        win_icon=""
        while IFS= read -r pane_id; do
            pf="$PANE_DIR/${sess}_${pane_id}.status"
            [ -f "$pf" ] || continue
            case "$(cat "$pf" 2>/dev/null)" in
                working) win_icon="⚡"; break ;;
                done)    [ "$win_icon" != "⚡" ] && win_icon="✓" ;;
                wait)    [ -z "$win_icon" ] && win_icon="⏸" ;;
            esac
        done < <(tmux list-panes -t "${sess}:${widx}" -F '#{pane_id}' 2>/dev/null)

        cur_mark=""
        [ "$sess" = "$current_session" ] && [ "$widx" = "$current_window" ] && cur_mark=" ●"

        if [ -n "$win_icon" ]; then
            display="    ${widx}  ${wname}  ${win_icon}${cur_mark}"
        else
            display="    ${widx}  ${wname}${cur_mark}"
        fi

        lines+=("${display}${TAB}${sess}:${widx}")
    done < <(tmux list-windows -t "$sess" -F "#{window_index}${TAB}#{window_name}" 2>/dev/null)

done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null)

# Feed into fzf; --with-nth=1 shows only the display column
choice=$(
    printf '%s\n' "${lines[@]}" \
    | fzf \
        --height=100% \
        --reverse \
        --no-border \
        --with-nth=1 \
        --delimiter="$TAB" \
        --prompt="  " \
        --color="fg:250,bg:-1,hl:214,fg+:255,bg+:236,hl+:214,prompt:75,pointer:214" \
    | cut -f2
)

[ -z "$choice" ] && exit 0

if [[ "$choice" == *:* ]]; then
    sess="${choice%%:*}"
    widx="${choice##*:}"
    tmux switch-client -t "$sess" 2>/dev/null
    tmux select-window -t "${sess}:${widx}" 2>/dev/null
else
    tmux switch-client -t "$choice" 2>/dev/null
fi
