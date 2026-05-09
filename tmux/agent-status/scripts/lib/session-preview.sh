#!/usr/bin/env bash
# session-preview.sh — fzf preview pane showing live session/window details
# Called by switcher.sh with the selected target: "session" or "session:winidx"

TARGET="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/state.sh"

now=$(date +%s)

fmt_elapsed() {
    local secs=$(( now - $1 ))
    (( secs < 0 )) && secs=0
    if   (( secs < 60  )); then printf '%ds'      "$secs"
    elif (( secs < 3600)); then printf '%dm%ds'   "$(( secs/60 ))" "$(( secs%60 ))"
    else                        printf '%dh%dm'   "$(( secs/3600 ))" "$(( (secs%3600)/60 ))"
    fi
}

# Extract session (and optional window) from target
if [[ "$TARGET" == *:* ]]; then
    focus_sess="${TARGET%%:*}"
    focus_win="${TARGET##*:}"
else
    focus_sess="$TARGET"
    focus_win=""
fi

# Colors (ANSI, work inside fzf preview)
R=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
GN=$'\033[32m'    # green  (done)
YL=$'\033[33m'    # yellow (working)
RD=$'\033[31m'    # red    (wait/permission)
BL=$'\033[34m'    # blue   (shell running)
CY=$'\033[36m'    # cyan   (shell done)

while IFS= read -r sess; do
    [ -z "$sess" ] && continue

    # Session header
    sf="$SESSION_DIR/${sess}.status"
    sess_status=$(cat "$sf" 2>/dev/null)
    case "$sess_status" in
        working) s_icon="${YL}⚡${R}" ;;
        done)    s_icon="${GN}✓${R}" ;;
        wait)    s_icon="${RD}⏸${R}" ;;
        *)       s_icon="  " ;;
    esac
    printf '%s %s%s%s\n' "$s_icon" "$BOLD" "$sess" "$R"

    # Windows
    while IFS=$'\t' read -r widx wname; do
        [ -z "$widx" ] && continue

        win_parts=()
        shell_parts=()

        while IFS= read -r pane_id; do
            # Claude status
            pf="$PANE_DIR/${sess}_${pane_id}.status"
            [ -f "$pf" ] || continue
            ps=$(cat "$pf" 2>/dev/null)

            tool_file="$PANE_DIR/${sess}_${pane_id}.tool"
            ts_file="$PANE_DIR/${sess}_${pane_id}.start_ts"

            case "$ps" in
                working)
                    tool=$(cat "$tool_file" 2>/dev/null)
                    elapsed_str=""
                    if [ -f "$ts_file" ]; then
                        ts=$(cat "$ts_file" 2>/dev/null)
                        elapsed_str=" ${DIM}$(fmt_elapsed "$ts")${R}"
                    fi
                    if [ -n "$tool" ]; then
                        win_parts+=("${YL}⚙${tool}${R}${elapsed_str}")
                    else
                        win_parts+=("${YL}⚡${R}${elapsed_str}")
                    fi
                    ;;
                done) win_parts+=("${GN}✓${R}") ;;
                wait) win_parts+=("${RD}⏸${R}") ;;
            esac

            # Shell running state for this pane
            rf="$SHELL_DIR/${sess}_${pane_id}.running"
            if [ -f "$rf" ]; then
                IFS=':' read -r cmd start_ts < "$rf"
                age=$(( now - start_ts ))
                if (( age >= 3 )); then
                    shell_parts+=("${BL}▶${cmd}${R} ${DIM}$(fmt_elapsed "$start_ts")${R}")
                fi
            fi

            # Shell recently done
            nf="$SHELL_DIR/${sess}_${pane_id}.notify"
            if [ -f "$nf" ]; then
                IFS=':' read -r elapsed wn finish_ts < "$nf"
                age=$(( now - finish_ts ))
                if (( age <= 30 )); then
                    shell_parts+=("${CY}⏱${cmd:-?} ${elapsed}s${R}")
                fi
            fi

        done < <(tmux list-panes -t "${sess}:${widx}" -F '#{pane_id}' 2>/dev/null)

        # Compose window line
        all_parts=("${win_parts[@]}" "${shell_parts[@]}")
        if [ "${#all_parts[@]}" -gt 0 ]; then
            status_str=$(IFS=' '; printf '%s' "${all_parts[*]}")
            printf '  %s  %s  %s\n' "$widx" "$wname" "$status_str"
        else
            printf '  %s  %s\n' "$widx" "$wname"
        fi

    done < <(tmux list-windows -t "$sess" -F "#{window_index}$'\t'#{window_name}" 2>/dev/null)

    printf '\n'
done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null)
