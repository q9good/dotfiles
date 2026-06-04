#!/usr/bin/env bash
# jump-back.sh — return to the window you were in before pressing Enter in a popup
#
# Uses a stack file (~/.cache/agent-status/location_stack) where each line is
# a saved "session:window_index". Supports nested jumps: A->B->C, then
# pressing prefix+Enter pops C->B, then B->A.

STACK_FILE="$HOME/.cache/agent-status/location_stack"

if [[ ! -f "$STACK_FILE" ]] || [[ ! -s "$STACK_FILE" ]]; then
    tmux display-message "No previous location"
    exit 0
fi

# Pop the last line from the stack
prev=$(tail -n1 "$STACK_FILE")
# Remove the last line (portable: works on both macOS and Linux)
if [[ $(wc -l < "$STACK_FILE") -le 1 ]]; then
    rm -f "$STACK_FILE"
else
    sed '$d' "$STACK_FILE" > "${STACK_FILE}.tmp" && mv "${STACK_FILE}.tmp" "$STACK_FILE"
fi

if [[ -z "$prev" ]]; then
    tmux display-message "No previous location"
    exit 0
fi

prev_session="${prev%%:*}"
prev_win="${prev#*:}"

tmux switch-client -t "$prev_session" 2>/dev/null
tmux select-window -t "${prev_session}:${prev_win}" 2>/dev/null
