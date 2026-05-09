#!/usr/bin/env bash
# inject-window-format.sh — append win-status.sh to window-status-format
# Called with a delay (sleep 7) from agent-status.tmux, after Catppuccin/tpm loads.

WIN_STATUS="bash $HOME/.config/tmux/agent-status/scripts/win-status.sh #{session_name} #{window_index}"

wsf=$(tmux show-option -gv window-status-format 2>/dev/null)
if [ -n "$wsf" ] && ! printf '%s' "$wsf" | grep -q "win-status"; then
    tmux set-option -g window-status-format "${wsf}#(${WIN_STATUS})"
fi

wscf=$(tmux show-option -gv window-status-current-format 2>/dev/null)
if [ -n "$wscf" ] && ! printf '%s' "$wscf" | grep -q "win-status"; then
    tmux set-option -g window-status-current-format "${wscf}#(${WIN_STATUS})"
fi
