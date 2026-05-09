#!/usr/bin/env bash
# switcher.sh — fzf session/window picker with agent + shell status indicators
#
# Layout:
#   ⚡  main ◀
#       1  nvim
#       2  build  ⚙Bash 2m10s  ▶npm 30s
#   ✓  work
#       1  claude  ✓
#
# Enter on a session line  → switch to that session (its active window)
# Enter on a window line   → switch to that session:window
# Press r / ctrl-r         → refresh the list

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/state.sh"
source "$SCRIPT_DIR/lib/format-status.sh"

TAB=$'\t'
now=$(date +%s)

generate_lines() {
    local current_session current_window
    current_session=$(tmux display-message -p '#{session_name}' 2>/dev/null)
    current_window=$(tmux display-message -p '#{window_index}' 2>/dev/null)

    while IFS= read -r sess; do
        [ -z "$sess" ] && continue

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

        printf '%s %s%s\t%s\n' "$icon" "$sess" "$marker" "$sess"

        while IFS=$'\t' read -r widx wname; do
            [ -z "$widx" ] && continue

            win_parts=()
            while IFS=$'\t' read -r pane_id pane_cmd; do
                local cs; cs=$(fmt_pane_claude "$sess" "$pane_id")
                [ -n "$cs" ] && win_parts+=("$cs")
                local ss; ss=$(fmt_pane_shell "$sess" "$pane_id" "$pane_cmd")
                [ -n "$ss" ] && win_parts+=("$ss")
            done < <(tmux list-panes -t "${sess}:${widx}" -F "#{pane_id}	#{pane_current_command}" 2>/dev/null)

            cur_mark=""
            [ "$sess" = "$current_session" ] && [ "$widx" = "$current_window" ] && cur_mark=" ●"

            if [ "${#win_parts[@]}" -gt 0 ]; then
                status_str="  $(IFS=' '; printf '%s' "${win_parts[*]}")"
                printf '    %s  %s%s%s\t%s\n' "$widx" "$wname" "$status_str" "$cur_mark" "${sess}:${widx}"
            else
                printf '    %s  %s%s\t%s\n' "$widx" "$wname" "$cur_mark" "${sess}:${widx}"
            fi

        done < <(tmux list-windows -t "$sess" -F "#{window_index}${TAB}#{window_name}" 2>/dev/null)

    done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null)
}

# --list mode: output lines for fzf reload binding
if [ "${1:-}" = "--list" ]; then
    generate_lines
    exit 0
fi

choice=$(
    generate_lines | fzf \
        --height=100% \
        --reverse \
        --no-border \
        --with-nth=1 \
        --delimiter="$TAB" \
        --prompt="  " \
        --color="fg:250,bg:-1,hl:214,fg+:255,bg+:236,hl+:214,prompt:75,pointer:214" \
        --preview="bash '$SCRIPT_DIR/lib/session-preview.sh' {2}" \
        --preview-window="right:45:wrap" \
        --bind="r:reload(bash '$SCRIPT_DIR/switcher.sh' --list)" \
        --bind="ctrl-r:reload(bash '$SCRIPT_DIR/switcher.sh' --list)" \
        --header="  r: refresh" \
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
