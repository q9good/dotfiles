# tmux config

Built on [Oh my tmux!](https://github.com/gpakosz/.tmux) with Catppuccin Mocha theme, vim-tmux-navigator, and a custom `agent-status` plugin for Claude Code session monitoring.

---

## Prefix key

`` ` `` (backtick). Press `` ` `` twice to send a literal backtick.

---

## Key bindings

### Panes

| Key | Action |
|-----|--------|
| `prefix + \` | Split horizontally (keep path) |
| `prefix + -` | Split vertically (keep path) |
| `prefix + h/j/k/l` | Select pane (left/down/up/right) |
| `prefix + H/J/K/L` | Resize pane by 2 |
| `prefix + >` / `<` | Swap pane with next / previous |
| `prefix + z` | Zoom / unzoom pane |
| `prefix + q` | Show pane numbers |
| `prefix + x` | Kill pane (with confirm) |
| `prefix + C-s` | Toggle pane synchronization |
| `prefix + k` | Clear screen + scrollback history |

Pane navigation also works seamlessly with Neovim via **vim-tmux-navigator**: `Ctrl+h/j/k/l` move between tmux panes and nvim splits without needing the prefix.

### Windows

| Key | Action |
|-----|--------|
| `prefix + c` | New window |
| `prefix + &` | Kill window (with confirm) |
| `prefix + ,` | Rename window |
| `prefix + 0-9` | Select window by index |
| `prefix + Tab` | Last window |
| `prefix + C-h` / `C-l` | Previous / next window |
| `prefix + C-S-H` / `C-S-L` | Swap window left / right |
| `prefix + Space` | Next layout |

### Sessions

| Key | Action |
|-----|--------|
| `prefix + S` | **Agent session switcher** (fzf popup, see below) |
| `prefix + N` | Jump to next Claude "done" session |
| `prefix + s` | tmux built-in session tree |
| `prefix + $` | Rename session |
| `prefix + d` | Detach |
| `prefix + BTab` | Switch to last session |

### Copy mode (vi)

| Key | Action |
|-----|--------|
| `prefix + Enter` | Enter copy mode |
| `v` | Begin selection |
| `C-v` | Rectangle selection |
| `y` | Copy selection → clipboard (xclip) |
| `H` / `L` | Start / end of line |
| `Escape` | Cancel |

`prefix + y` copies the tmux buffer to the OS clipboard.

### Misc

| Key | Action |
|-----|--------|
| `prefix + m` | Toggle mouse |
| `prefix + C-n` | Toggle monitor-silence (10 s threshold) |
| `prefix + r` | Reload config |
| `prefix + e` | Edit `.tmux.conf.local` |
| `prefix + t` | Clock |
| `prefix + i` | Display message |
| `prefix + ?` | List key bindings |

---

## Plugins (via TPM)

| Plugin | Purpose |
|--------|---------|
| `tmux-plugins/tmux-yank` | Clipboard integration (`y` in copy mode) |
| `catppuccin/tmux` | Catppuccin Mocha theme |

TPM bindings: `prefix+I` install, `prefix+u` update, `prefix+M-u` clean.

> **Note:** Catppuccin loads via `sleep 5` in the background. The window-format injection (agent-status) runs at `sleep 7` to execute after it.

---

## agent-status plugin

Located at `~/.config/tmux/agent-status/`. Tracks Claude Code sessions and long-running shell commands across tmux panes.

### Status indicators

**Status bar (right):** `⚡2 ⏸1 ✓1 ▶1 ⏱[build]`

| Symbol | Meaning |
|--------|---------|
| `⚡N` | N sessions with Claude actively working |
| `⏸N` | N sessions waiting for permission approval |
| `✓N` | N sessions with Claude done (unread) |
| `▶N` | N shell commands running ≥ 3 s |
| `⏱[win]` | Recent long shell command finished in window |

**Window tab bar:** `1 api ⚙Bash 1m30s zsh▶make 45s`

| Token | Meaning |
|-------|---------|
| `⚙Tool Ns` | Claude using a tool (e.g. Bash, Edit) |
| `⚡ Ns` | Claude generating (no active tool) |
| `⏸` | Waiting for permission |
| `✓` | Claude done |
| `zsh` / `bash` / `fish` | Shell idle |
| `zsh▶cmd Ns` | Shell running command for N seconds |

### Session switcher (`prefix+S`)

fzf popup showing all sessions and their windows with live status. Each window line shows Claude + shell state for all panes.

- `Enter` on a session line → switch to that session
- `Enter` on a window line → switch to that session:window
- `r` / `Ctrl-r` → refresh list

### Notification popups

A small popup appears top-right when:
- **Claude finishes** (`Stop`) — green `▲ ▲`, auto-dismisses in 5 s, skipped if you're already viewing that window
- **Permission needed** (`Notification: "to use …"`) — red `▓ ▓`, auto-dismisses in 10 s, always shown
- **Long shell command done** — blue `⏱`, auto-dismisses in 5 s

Press `↵` to jump to the window, `q` to dismiss.

### Shell integration

Source in your shell rc to enable shell command tracking:

```sh
# zsh / bash: add to ~/.zshrc or ~/.bashrc
source ~/.config/shell/common.sh
```

```fish
# fish: add to ~/.config/fish/config.fish
source ~/.config/shell/common.fish
```

Commands running for ≥ 8 s trigger a notification when they finish. The threshold is set by `AS_NOTIFY_THRESHOLD` (default 8).

### Claude Code hooks

Registered in `~/.claude/settings.json`. The hook script is `agent-status/hooks/hook.sh`.

| Hook event | Action |
|------------|--------|
| `UserPromptSubmit` | Set pane → working |
| `PreToolUse` | Set pane → working, record tool name |
| `PostToolUse` | Clear tool name (show ⚡ not ⚙Tool) |
| `Stop` | Set pane → done, ring bell, show popup |
| `Notification` (permission) | Set pane → wait, ring bell, show popup |
| `Notification` (idle) | Ring bell only |

State files live in `~/.cache/agent-status/`:

```
panes/     <session>_<pane>.{status,tool,start_ts}
sessions/  <session>.status
shell/     <session>_<pane>.{running,notify}
```

### Scripts

| Script | Description |
|--------|-------------|
| `hooks/hook.sh` | Claude Code hook handler |
| `scripts/status-line.sh` | Status-right component (⚡✓⏸▶⏱) |
| `scripts/win-status.sh` | Per-window tab status |
| `scripts/switcher.sh` | fzf session/window picker |
| `scripts/popup.sh` | Notification popup dispatcher + renderer |
| `scripts/notify-shell.sh` | Called by shell integration on long-cmd finish |
| `scripts/inject-window-format.sh` | Appends win-status to window-status-format post-Catppuccin |
| `scripts/lib/format-status.sh` | Shared pane status formatting (`fmt_pane_claude`, `fmt_pane_shell`) |
| `scripts/lib/state.sh` | Shared state directory constants |
| `scripts/lib/session-preview.sh` | fzf preview pane renderer |
| `scripts/lib/next-done.sh` | Jump to next done agent session |
