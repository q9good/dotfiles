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

TAB=$'\t'
now=$(date +%s)

fmt_elapsed() {
    local secs=$(( now - $1 ))
    (( secs < 0 )) && secs=0
    if   (( secs < 60  )); then printf '%ds'    "$secs"
    elif (( secs < 3600)); then printf '%dm%ds' "$(( secs/60 ))" "$(( secs%60 ))"
    else                        printf '%dh%dm' "$(( secs/3600 ))" "$(( (secs%3600)/60 ))"
    fi
}

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

            while IFS= read -r pane_id; do
                # Claude state with tool name and elapsed time
                pf="$PANE_DIR/${sess}_${pane_id}.status"
                [ -f "$pf" ] || continue
                ps=$(cat "$pf" 2>/dev/null)

                case "$ps" in
                    working)
                        tool=$(cat "$PANE_DIR/${sess}_${pane_id}.tool" 2>/dev/null)
                        ts_file="$PANE_DIR/${sess}_${pane_id}.start_ts"
                        elapsed_str=""
                        if [ -f "$ts_file" ]; then
                            ts=$(cat "$ts_file" 2>/dev/null)
                            elapsed_str=" $(fmt_elapsed "$ts")"
                        fi
                        if [ -n "$tool" ]; then
                            win_parts+=("⚙${tool}${elapsed_str}")
                        else
                            win_parts+=("⚡${elapsed_str}")
                        fi
                        ;;
                    done) win_parts+=("✓") ;;
                    wait) win_parts+=("⏸") ;;
                esac

                # Shell running state
                rf="$SHELL_DIR/${sess}_${pane_id}.running"
                if [ -f "$rf" ]; then
                    IFS=':' read -r cmd start_ts < "$rf"
                    age=$(( now - start_ts ))
                    if (( age >= 3 )); then
                        win_parts+=("▶${cmd} $(fmt_elapsed "$start_ts")")
                    fi
                fi
            done < <(tmux list-panes -t "${sess}:${widx}" -F '#{pane_id}' 2>/dev/null)

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
