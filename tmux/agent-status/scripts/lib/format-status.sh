#!/usr/bin/env bash
# format-status.sh — shared pane status formatting
# Requires: $now (epoch seconds), $PANE_DIR, $SHELL_DIR (set by state.sh)

fmt_elapsed() {
    local secs=$(( now - $1 ))
    (( secs < 0 )) && secs=0
    if   (( secs < 60  )); then printf '%ds'    "$secs"
    elif (( secs < 3600)); then printf '%dm%ds' "$(( secs/60 ))" "$(( secs%60 ))"
    else                        printf '%dh%dm' "$(( secs/3600 ))" "$(( (secs%3600)/60 ))"
    fi
}

# fmt_pane_claude SESS PANE_ID
# Print Claude status for one pane: "⚙Bash 2m" | "⚡ 45s" | "⏸" | "✓" | (nothing)
fmt_pane_claude() {
    local sess="$1" pane_id="$2"
    local pf="$PANE_DIR/${sess}_${pane_id}.status"
    [ -f "$pf" ] || return
    local ps; ps=$(cat "$pf" 2>/dev/null)
    local tool ts_file elapsed_str
    case "$ps" in
        working)
            tool=$(cat "$PANE_DIR/${sess}_${pane_id}.tool" 2>/dev/null)
            elapsed_str=""
            ts_file="$PANE_DIR/${sess}_${pane_id}.start_ts"
            if [ -f "$ts_file" ]; then
                elapsed_str=" $(fmt_elapsed "$(cat "$ts_file" 2>/dev/null)")"
            fi
            if [ -n "$tool" ]; then
                printf '⚙%s%s' "$tool" "$elapsed_str"
            else
                printf '⚡%s' "$elapsed_str"
            fi
            ;;
        wait) printf '⏸' ;;
        done) printf '✓' ;;
    esac
}

# fmt_pane_shell SESS PANE_ID
# Print shell running status for one pane: "▶npm 30s" | (nothing)
fmt_pane_shell() {
    local sess="$1" pane_id="$2"
    local rf="$SHELL_DIR/${sess}_${pane_id}.running"
    [ -f "$rf" ] || return
    local cmd start_ts
    IFS=':' read -r cmd start_ts < "$rf"
    local age=$(( now - start_ts ))
    (( age >= 3 )) && printf '▶%s %s' "$cmd" "$(fmt_elapsed "$start_ts")"
}
