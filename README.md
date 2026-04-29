# Dotfiles

Personal dotfiles managed in `~/.config`, including configurations for:

- **nvim** — [LazyVim](https://www.lazyvim.org/) based Neovim configuration with Catppuccin Mocha theme
- **tmux** — [Oh my tmux!](https://github.com/gpakosz/.tmux) with Catppuccin Mocha theme, vim-tmux-navigator, tpm plugins
- **fish** — Fish shell configuration
- **yazi** — Terminal file manager with plugins (smart-enter, full-border, git, chmod, diff, etc.)
- **htop** — System monitor configuration
- **uv** — Python package manager configuration

## Features

### Neovim LSP Support

Enabled via LazyVim extras (`lazyvim.json`):

| Language | Extra | LSP Server |
|----------|-------|------------|
| C/C++ | `lang.clangd` | clangd |
| Rust | `lang.rust` | rust-analyzer |
| Python | `lang.python` | basedpyright / pyright |
| Markdown | `lang.markdown` | marksman |

> **clangd tip**: clangd looks for `compile_commands.json` in the project root and `build/` by default. For custom paths, create a `.clangd` file in the project root:
> ```yaml
> CompileFlags:
>   CompilationDatabase: /path/to/build/directory
> ```

### Seamless Navigation

`C-h/j/k/l` works across both tmux panes and Neovim splits thanks to [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator), configured on both sides.

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
- **Install common tools** — curl, git, tmux, fzf, fd, ripgrep, bat, eza, zoxide, lazygit, lua, unzip, jq, clipboard tools
- **Install yazi** — via `brew` (macOS), `pacman` (Arch), or `curl` (Ubuntu/Debian)
- **Install yazi plugins** — smart-enter, full-border, toggle-pane, jump-to-char, git, smart-filter, chmod, smart-paste, diff, mime-ext
- **Configure tmux** — symlink `~/.tmux.conf`, copy `.tmux.conf.local`
- **Install tpm** — tmux plugin manager
- **Ghostty terminfo** — prints instructions if `xterm-ghostty` terminfo is missing (for SSH)

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

## Cheatsheet

### Tmux (Oh my tmux!, prefix = `` ` ``)

#### Session & Window

| Key | Action |
|-----|--------|
| `prefix + c` | New window |
| `prefix + ,` | Rename window |
| `prefix + &` | Kill window |
| `prefix + n` / `p` | Next / previous window |
| `prefix + 0-9` | Switch to window by number |
| `prefix + d` | Detach session |
| `prefix +  | Rename session |
| `prefix + s` | List sessions |

#### Pane

| Key | Action |
|-----|--------|
| `prefix + -` | Split horizontally (below) |
| `prefix + \` | Split vertically (right) |
| `C-h/j/k/l` | Navigate panes & nvim windows seamlessly (vim-tmux-navigator) |
| `prefix + q` | Show pane numbers |
| `prefix + z` | Toggle pane zoom |
| `prefix + x` | Kill pane |
| `prefix + +` | Maximize pane (Oh my tmux!) |
| `prefix + m` | Toggle mouse on/off |
| `prefix + S` | Synchronize panes (broadcast input to all panes) |
| `prefix + A` | Unsynchronize panes |

#### Plugins & Config

| Key | Action |
|-----|--------|
| `prefix + I` | Install tpm plugins |
| `prefix + u` | Update tpm plugins |
| `prefix + r` | Reload tmux configuration |
| `prefix + e` | Edit `.tmux.conf.local` |
| `prefix + t` | Show clock |

#### Copy Mode

| Key | Action |
|-----|--------|
| `prefix + Enter` | Enter copy mode |
| `v` (in copy mode) | Begin selection |
| `y` (in copy mode) | Copy selection (tmux-yank, auto-copies to OS clipboard) |
| `prefix + p` | Paste buffer |

---

### Neovim (LazyVim)

#### General

| Key | Action |
|-----|--------|
| `<Space>` | Leader key |
| `<leader>qq` | Quit all |
| `<leader>e` | Open file explorer (neo-tree) |
| `<leader>ff` | Find files (Telescope) |
| `<leader>fg` / `<leader>/` | Live grep (Telescope) |
| `<leader>fb` | Find buffers |
| `<leader>fr` | Recent files |
| `<leader>:` | Command history |

#### Window & Buffer

| Key | Action |
|-----|--------|
| `C-h/j/k/l` | Navigate between nvim splits & tmux panes (vim-tmux-navigator) |
| `<leader>-` | Split below |
| `<leader>\|` | Split right |
| `<leader>wd` | Close current split window |
| `C-w c` | Close current split window (Vim native) |
| `<leader>wo` | Close all other split windows |
| `C-w o` | Close all other split windows (Vim native) |
| `<leader>bd` | Delete buffer |
| `[b` / `]b` | Previous / next buffer |

#### LSP & Code

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | Go to references |
| `gI` | Go to implementation |
| `gy` | Go to type definition |
| `K` | Hover documentation |
| `<leader>ca` | Code action |
| `<leader>cr` | Rename symbol |
| `<leader>cd` | Line diagnostics |
| `[d` / `]d` | Previous / next diagnostic |
| `<leader>cl` | LSP info |

#### Git

| Key | Action |
|-----|--------|
| `<leader>gg` | LazyGit (if installed) |
| `<leader>ghb` | Git blame line |
| `<leader>ghp` | Preview hunk |
| `<leader>ghs` | Stage hunk |
| `<leader>ghr` | Reset hunk |
| `[h` / `]h` | Previous / next hunk |

---

### Yazi (Terminal File Manager)

#### Navigation

| Key | Action |
|-----|--------|
| `h` / `l` | Parent directory / enter directory or open file (smart-enter) |
| `j` / `k` | Move down / up |
| `J` / `K` | Navigate parent directory entries (parent-arrow) |
| `g g` | Go to top |
| `G` | Go to bottom |
| `g r` | cd to Git repository root |
| `f` | Jump to character (jump-to-char) |
| `F` | Smart filter |

#### File Operations

| Key | Action |
|-----|--------|
| `Space` | Toggle file selection |
| `v` | Enter visual (bulk select) mode |
| `y` | Copy (yank) selected |
| `x` | Cut selected |
| `p` | Paste |
| `P` | Paste into hovered directory (smart-paste) |
| `d` | Trash selected |
| `D` | Permanently delete selected |
| `r` | Rename |
| `a` | Create file |
| `c m` | Chmod on selected files |
| `d d` | Diff selected with hovered file |
| `.` | Toggle hidden files |

#### Tabs & UI

| Key | Action |
|-----|--------|
| `t t` | New tab in hovered directory (smart-tab) |
| `1-9` | Switch to tab by number |
| `T` | Maximize / restore preview pane |
| `t h` | Hide / show preview pane |
| `q` | Quit (confirms if multiple tabs open) |
| `!` | Open shell in current directory |

---

## Tmux Theme

The current theme is **Catppuccin Mocha**, loaded via tpm plugin. To change:

1. `prefix + e` to edit `.tmux.conf.local`
2. Modify the `@catppuccin_flavor` option or swap the theme plugin
3. Save and `prefix + r` to reload

## Supported Platforms

| Platform | Package Manager | Notes |
|----------|----------------|-------|
| **macOS** | `brew` | Common tools auto-installed |
| **Arch Linux** | `pacman` | Common tools auto-installed |
| **Ubuntu/Debian** | `curl` | yazi as musl binary; other tools need manual install |
