#!/usr/bin/env bash
# inject-window-format.sh — insert win-status.sh into window-status-format
# Called with a delay (sleep 7) from agent-status.tmux, after Catppuccin/tpm loads.
# Inserts status BEFORE #T (pane title) so indicators appear first in the tab.

WIN_STATUS="bash $HOME/.config/tmux/agent-status/scripts/win-status.sh #{session_name} #{window_index}"
MARKER="#(${WIN_STATUS})"

inject() {
    local option="$1"
    local fmt
    fmt=$(tmux show-option -gv "$option" 2>/dev/null)
    [ -n "$fmt" ] || return
    printf '%s' "$fmt" | grep -q "win-status" && return
    # Insert before " #T" so status appears between window index and title
    local new="${fmt/ #T/${MARKER} #T}"
    if [ "$new" = "$fmt" ]; then
        new="${fmt}${MARKER}"
    fi
    tmux set-option -g "$option" "$new"
}

inject window-status-format
inject window-status-current-format
