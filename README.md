# Dotfiles

Personal dotfiles managed in `~/.config`, including configurations for:

- **nvim** — [LazyVim](https://www.lazyvim.org/) based Neovim configuration
- **tmux** — [Oh my tmux!](https://github.com/gpakosz/.tmux) with Catppuccin theme, vim-tmux-navigator, tpm plugins
- **fish** — Fish shell configuration
- **yazi** — Terminal file manager with plugins
- **htop** — System monitor configuration

## Quick Start (New Machine)

### 1. Clone into `~/.config`

If `~/.config` already exists and is non-empty:

```bash
cd ~/.config

# Initialize git repo
git init

# Add remote
git remote add origin git@github.com:q9good/dotfiles.git

# Fetch remote content (won't touch working directory)
git fetch origin

# Checkout repo files, overwriting existing ones, leaving others untouched
git checkout origin/main -- .

# Set local branch to track remote, so `git pull` works
git branch -M main
git reset origin/main
git branch --set-upstream-to=origin/main main
```

### 2. Run the installer

```bash
sh ~/.config/install.sh
```

This will:
- **Install yazi** — via `brew` (macOS), `pacman` (Arch), or `curl` (Ubuntu/Debian)
- **Install yazi plugins** — smart-enter, full-border, git, chmod, etc.
- **Configure tmux** — symlink `~/.tmux.conf`, copy `.tmux.conf.local`
- **Install tpm** — tmux plugin manager

### 3. Finalize tmux setup

After running `install.sh`, start tmux and wait ~15 seconds for plugins to auto-install:

```bash
tmux
```

If `prefix + I` doesn't work immediately, run this inside tmux to manually trigger plugin installation:

```bash
# Inside a tmux pane:
cut -c3- ~/.tmux.conf | sh -s _apply_plugins
```

Then `prefix + I` should work, and Catppuccin theme will be active.

## Tmux Key Bindings

| Key | Action |
|-----|--------|
| `C-h/j/k/l` | Navigate between tmux panes and nvim windows (vim-tmux-navigator) |
| `prefix + I` | Install tpm plugins |
| `prefix + u` | Update tpm plugins |
| `prefix + r` | Reload tmux configuration |
| `prefix + e` | Edit `.tmux.conf.local` |

## Switching Tmux Theme

Both **Catppuccin** (default) and **Tokyo Night** are installed. To switch:

1. `prefix + e` to edit `.tmux.conf.local`
2. In the `# -- active plugins ---` section, put your preferred theme **last** (last loaded wins)
3. Save and `prefix + r` to reload

## Supported Platforms

| Platform | Package Manager | Notes |
|----------|----------------|-------|
| **macOS** | `brew` | |
| **Arch Linux** | `pacman` | |
| **Ubuntu/Debian** | `curl` | yazi installed as musl static binary |
