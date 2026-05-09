#!/usr/bin/env bash
# agent-status.tmux — plugin entry point
# Run via `run-shell` from tmux.conf.local

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Make all scripts executable
chmod +x \
    "$CURRENT_DIR/hooks/hook.sh" \
    "$CURRENT_DIR/scripts/popup.sh" \
    "$CURRENT_DIR/scripts/notify-shell.sh" \
    "$CURRENT_DIR/scripts/status-line.sh" \
    "$CURRENT_DIR/scripts/switcher.sh" \
    "$CURRENT_DIR/scripts/win-status.sh" \
    "$CURRENT_DIR/scripts/inject-window-format.sh" \
    "$CURRENT_DIR/scripts/lib/next-done.sh" \
    "$CURRENT_DIR/scripts/lib/session-preview.sh" \
    "$CURRENT_DIR/scripts/lib/state.sh" \
    2>/dev/null

# ── Key bindings ──────────────────────────────────────────────────────────────
#
# prefix+S  Agent session/window switcher (fzf, shows session+window tree)
#           Previously: synchronize panes (moved to prefix+C-s in tmux.conf.local)
#
# prefix+N  Jump to next "done" agent session
#           Previously: monitor-silence toggle (moved to prefix+C-n)

# Clean up A which was the old Oh My Tmux sync binding.
tmux unbind A   2>/dev/null || true

tmux bind-key S display-popup \
    -E \
    -w 95 -h 28 \
    -T " Sessions " \
    -s "fg=#9E8C5D,bg=#1E1E2E" \
    -S "fg=#9E8C5D" \
    "$CURRENT_DIR/scripts/switcher.sh"

tmux bind-key N run-shell "$CURRENT_DIR/scripts/lib/next-done.sh"

# ── Status bar integration ────────────────────────────────────────────────────
tmux set-option -g status-interval 2

# Append our component to status-right (idempotent check)
current_right=$(tmux show-option -gqv status-right)
if ! printf '%s' "$current_right" | grep -q "agent-status"; then
    tmux set-option -ga status-right " #($CURRENT_DIR/scripts/status-line.sh)"
fi

# ── Window tab status injection ───────────────────────────────────────────────
# Catppuccin (via tpm) loads with `sleep 5` and overwrites window-status-format.
# We inject after it by running our script at sleep 7.
tmux run-shell -b "sleep 7 && bash '$CURRENT_DIR/scripts/inject-window-format.sh'"
