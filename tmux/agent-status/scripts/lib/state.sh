#!/usr/bin/env bash
# Shared state directory constants for agent-status plugin

STATE_DIR="$HOME/.cache/agent-status"
PANE_DIR="$STATE_DIR/panes"
SESSION_DIR="$STATE_DIR/sessions"
SHELL_DIR="$STATE_DIR/shell"

mkdir -p "$PANE_DIR" "$SESSION_DIR" "$SHELL_DIR"
