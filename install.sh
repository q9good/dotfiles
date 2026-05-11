#!/bin/sh
# Dotfiles installer
# Installs: common tools, yazi, tmux (Oh my tmux! + plugins), yazi plugins
# Compatible with: bash, zsh, fish (via shebang)
# Supported OS: macOS (brew), Arch Linux (pacman), Ubuntu/Debian (curl)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# =============================================
# Detect OS and package manager
# =============================================
detect_os() {
    case "$(uname -s)" in
        Darwin)
            OS="macos"
            ;;
        Linux)
            if [ -f /etc/arch-release ]; then
                OS="arch"
            elif [ -f /etc/debian_version ]; then
                OS="ubuntu"
            else
                OS="linux-unknown"
            fi
            ;;
        *)
            OS="unknown"
            ;;
    esac
    echo "Detected OS: $OS"
}

# =============================================
# Helpers
# =============================================
install_with_brew() {
    if ! command -v brew >/dev/null 2>&1; then
        echo "Error: brew not found. Install Homebrew first: https://brew.sh"
        exit 1
    fi
    echo "Installing with brew: $*"
    brew install "$@"
}

install_with_pacman() {
    echo "Installing with pacman: $*"
    sudo pacman -S --needed --noconfirm "$@"
}

is_installed() {
    command -v "$1" >/dev/null 2>&1
}

# Run a command with timeout (default 300s). Kills entire process group on timeout.
# Usage: run_with_timeout <seconds> <command...>
# Example: run_with_timeout 300 npm install -g some-package
# Returns 124 on timeout.
run_with_timeout() {
    _rt_secs="$1"
    shift
    # Disable set -e locally so non-zero exits/timeout don't abort the whole script
    set +e
    if command -v timeout >/dev/null 2>&1; then
        if timeout --help 2>&1 | grep -q -- '--signal'; then
            timeout --signal=KILL "$_rt_secs" "$@"
        else
            timeout -s KILL "$_rt_secs" "$@"
        fi
        _rt_ret=$?
    else
        "$@" &
        _rt_pid=$!
        ( sleep "$_rt_secs" && kill -TERM "$_rt_pid" 2>/dev/null && sleep 2 && kill -9 "$_rt_pid" 2>/dev/null || true ) &
        _rt_wdog=$!
        wait "$_rt_pid" 2>/dev/null
        _rt_ret=$?
        kill "$_rt_wdog" 2>/dev/null || true
        wait "$_rt_wdog" 2>/dev/null || true
    fi
    # Map SIGKILL (137) and standard timeout (124) to our timeout code (124)
    if [ "$_rt_ret" -eq 137 ] || [ "$_rt_ret" -eq 124 ]; then
        echo "  [!] Command timed out after ${_rt_secs}s"
        return 124
    fi
    # Re-enable set -e before returning
    set -e
    return "$_rt_ret"
}

# =============================================
# Common tools
# =============================================

# Install lazygit from GitHub release binary (for Ubuntu/Debian)
install_lazygit_binary() {
    if is_installed lazygit; then
        echo "  lazygit already installed: $(lazygit --version 2>/dev/null | head -1)"
        return
    fi
    echo "  Installing lazygit from GitHub release..."
    LAZYGIT_VERSION="$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -Po '"tag_name": "v\K[^"]*')"
    if [ -z "$LAZYGIT_VERSION" ]; then
        echo "  [!] Failed to fetch lazygit version. Please install manually."
        return
    fi
    ARCH="$(uname -m)"
    case "$ARCH" in
        x86_64)  LAZYGIT_ARCH="x86_64" ;;
        aarch64) LAZYGIT_ARCH="arm64" ;;
        *)       echo "  [!] Unsupported arch: $ARCH"; return ;;
    esac
    mkdir -p ~/.local/bin
    curl -fLo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz"
    tar xzf /tmp/lazygit.tar.gz -C /tmp lazygit
    mv /tmp/lazygit ~/.local/bin/lazygit
    rm -f /tmp/lazygit.tar.gz
    echo "  lazygit installed: $(~/.local/bin/lazygit --version 2>/dev/null | head -1)"
}

# Install uv (Python package manager)
install_uv() {
    if is_installed uv; then
        echo "  Already installed: uv $(uv --version 2>/dev/null)"
        return
    fi
    echo "  Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    # Ensure uv is on PATH for the rest of this script
    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
}

# Check if a clipboard tool is available (for tmux-yank)
has_clipboard_tool() {
    is_installed pbcopy || is_installed xsel || is_installed xclip || is_installed wl-copy
}

# Collect missing tools into TOOLS_TO_INSTALL (space-separated)
# Usage: check_tool <command> [package_name]
check_tool() {
    if is_installed "$1"; then
        echo "  Already installed: $1"
    else
        TOOLS_TO_INSTALL="$TOOLS_TO_INSTALL ${2:-$1}"
    fi
}

install_common_tools() {
    echo "=== Installing common tools ==="
    TOOLS_TO_INSTALL=""

    check_tool curl
    check_tool git
    check_tool tmux
    check_tool fzf
    check_tool fd
    check_tool rg ripgrep
    check_tool bat
    check_tool eza
    check_tool zoxide
    check_tool lazygit
    check_tool ruff
    check_tool lua
    check_tool unzip
    check_tool jq

    # Clipboard tools (needed by tmux-yank for mouse copy)
    if ! has_clipboard_tool; then
        case "$OS" in
            macos)
                # pbcopy is built-in, should never reach here
                ;;
            arch)
                TOOLS_TO_INSTALL="$TOOLS_TO_INSTALL xsel xclip wl-clipboard"
                ;;
            ubuntu)
                TOOLS_TO_INSTALL="$TOOLS_TO_INSTALL xsel xclip"
                ;;
        esac
    else
        echo "  Clipboard tool available."
    fi

    if [ -z "$TOOLS_TO_INSTALL" ]; then
        echo "All common tools already installed."
        return
    fi

    echo "  Missing:$TOOLS_TO_INSTALL"

    case "$OS" in
        macos)
            install_with_brew $TOOLS_TO_INSTALL
            ;;
        arch)
            install_with_pacman $TOOLS_TO_INSTALL
            ;;
        ubuntu)
            # lazygit: install from GitHub release binary
            if echo "$TOOLS_TO_INSTALL" | grep -q "lazygit"; then
                install_lazygit_binary
                TOOLS_TO_INSTALL="$(echo "$TOOLS_TO_INSTALL" | sed 's/ *lazygit */ /g')"
            fi
            # ruff: install via uv
            if echo "$TOOLS_TO_INSTALL" | grep -q "ruff"; then
                install_uv
                if is_installed uv; then
                    echo "  Installing ruff via uv..."
                    uv tool install ruff
                else
                    echo "  [!] uv not available, skipping ruff."
                fi
                TOOLS_TO_INSTALL="$(echo "$TOOLS_TO_INSTALL" | sed 's/ *ruff */ /g')"
            fi
            # Tools installable via cargo
            CARGO_TOOLS=""
            REMAINING_TOOLS=""
            for tool in $TOOLS_TO_INSTALL; do
                case "$tool" in
                    fd)      CARGO_TOOLS="$CARGO_TOOLS fd-find" ;;
                    ripgrep|bat|eza|zoxide) CARGO_TOOLS="$CARGO_TOOLS $tool" ;;
                    *) REMAINING_TOOLS="$REMAINING_TOOLS $tool" ;;
                esac
            done
            if [ -n "$(echo "$CARGO_TOOLS" | tr -d ' ')" ]; then
                if is_installed cargo; then
                    echo "  Installing via cargo:$CARGO_TOOLS"
                    cargo install $CARGO_TOOLS
                else
                    echo "  [!] cargo not found. Please install Rust first, then run: cargo install$CARGO_TOOLS"
                fi
            fi
            if [ -n "$(echo "$REMAINING_TOOLS" | tr -d ' ')" ]; then
                echo "  [!] Please install the following manually:"
                echo "     $REMAINING_TOOLS"
            fi
            ;;
        *)
            echo "  [!] Unsupported OS. Please install manually:$TOOLS_TO_INSTALL"
            ;;
    esac
}

# =============================================
# Ghostty terminfo (for SSH into servers)
# Fixes: "missing or unsuitable terminal: xterm-ghostty"
# =============================================
install_ghostty_terminfo() {
    if infocmp xterm-ghostty >/dev/null 2>&1 && [ -n "$(infocmp xterm-ghostty 2>/dev/null)" ]; then
        echo "Ghostty terminfo already installed."
        return
    fi
    echo "=== Ghostty terminfo ==="
    echo "  [!] xterm-ghostty terminfo not found on this machine."
    echo "  If you use Ghostty to SSH into this server, run the following"
    echo "  from your LOCAL Ghostty terminal to install the terminfo:"
    echo ""
    echo "      infocmp -x xterm-ghostty | ssh -p <port> <user>@<host> 'mkdir -p ~/.terminfo && tic -x -'"
    echo ""
    echo "  Or set a TERM fallback in your local ~/.ssh/config:"
    echo ""
    echo "      Host <alias>"
    echo "          SetEnv TERM=xterm-256color"
}
# =============================================
# Yazi - Terminal file manager
# =============================================
install_yazi() {
    echo "=== Installing Yazi ==="
    if is_installed yazi; then
        echo "Yazi already installed: $(yazi --version)"
        return
    fi

    case "$OS" in
        macos)
            install_with_brew yazi
            ;;
        arch)
            install_with_pacman yazi
            ;;
        ubuntu|linux-unknown)
            mkdir -p ~/.local/bin
            ARCH="$(uname -m)"
            case "$ARCH" in
                x86_64)  YAZI_TARGET="x86_64-unknown-linux-musl" ;;
                aarch64) YAZI_TARGET="aarch64-unknown-linux-musl" ;;
                *)       echo "Unsupported arch: $ARCH"; exit 1 ;;
            esac
            curl -fLo /tmp/yazi.zip "https://github.com/sxyazi/yazi/releases/latest/download/yazi-${YAZI_TARGET}.zip"
            unzip -o /tmp/yazi.zip -d /tmp/yazi-extract
            mv "/tmp/yazi-extract/yazi-${YAZI_TARGET}/yazi" ~/.local/bin/yazi
            mv "/tmp/yazi-extract/yazi-${YAZI_TARGET}/ya" ~/.local/bin/ya
            rm -rf /tmp/yazi.zip /tmp/yazi-extract
            ;;
        *)
            echo "Unsupported OS for Yazi installation"
            exit 1
            ;;
    esac
    echo "Yazi installed: $(yazi --version 2>/dev/null || ~/.local/bin/yazi --version 2>/dev/null)"
}

# =============================================
# Yazi plugins (via ya pkg)
# =============================================
install_yazi_plugins() {
    echo "=== Installing Yazi plugins ==="
    YA_CMD="$(command -v ya 2>/dev/null || echo "$HOME/.local/bin/ya")"
    INSTALLED_PLUGINS="$("$YA_CMD" pkg list 2>/dev/null || true)"

    yazi_pkg_add() {
        if echo "$INSTALLED_PLUGINS" | grep -q "$1"; then
            echo "  Already installed: $1"
        else
            "$YA_CMD" pkg add "$1"
        fi
    }

    yazi_pkg_add yazi-rs/plugins:smart-enter
    yazi_pkg_add yazi-rs/plugins:full-border
    yazi_pkg_add yazi-rs/plugins:toggle-pane
    yazi_pkg_add yazi-rs/plugins:jump-to-char
    yazi_pkg_add yazi-rs/plugins:git
    yazi_pkg_add yazi-rs/plugins:smart-filter
    yazi_pkg_add yazi-rs/plugins:chmod
    yazi_pkg_add yazi-rs/plugins:smart-paste
    yazi_pkg_add yazi-rs/plugins:diff
    yazi_pkg_add yazi-rs/plugins:mime-ext
    yazi_pkg_add ndtoan96/ouch
    echo "Yazi plugins done."
}

# =============================================
# ouch — archive compression/decompression CLI
# Used by ouch.yazi plugin for compress/extract in yazi
# =============================================
install_ouch() {
    echo "=== Installing ouch ==="
    if is_installed ouch; then
        echo "ouch already installed: $(ouch --version 2>/dev/null)"
        return
    fi
    if is_installed cargo; then
        echo "  Installing ouch via cargo..."
        cargo install ouch
    else
        echo "  [!] cargo not found. Please install Rust first, then run: cargo install ouch"
    fi
}

# =============================================
# Oh my tmux! configuration
# =============================================
configure_tmux() {
    echo "=== Configuring tmux (Oh my tmux!) ==="
    TMUX_SOURCE="$SCRIPT_DIR/tmux/.tmux.conf"
    TMUX_TARGET="$HOME/.tmux.conf"
    TMUX_LOCAL_SOURCE="$SCRIPT_DIR/tmux/.tmux.conf.local"
    TMUX_LOCAL_TARGET="$HOME/.tmux.conf.local"

    if [ ! -f "$TMUX_SOURCE" ]; then
        echo "Warning: source not found: $TMUX_SOURCE, skipping tmux config."
        return
    fi

    if [ -L "$TMUX_TARGET" ]; then
        CURRENT_LINK="$(readlink "$TMUX_TARGET")"
        if [ "$CURRENT_LINK" = "$TMUX_SOURCE" ]; then
            echo "Symlink already correct: $TMUX_TARGET"
        else
            echo "Updating symlink: $TMUX_TARGET (was $CURRENT_LINK)"
            rm "$TMUX_TARGET"
            ln -s "$TMUX_SOURCE" "$TMUX_TARGET"
        fi
    else
        [ -e "$TMUX_TARGET" ] && mv "$TMUX_TARGET" "$TMUX_TARGET.bak.$(date +%Y%m%d%H%M%S)"
        ln -s "$TMUX_SOURCE" "$TMUX_TARGET"
        echo "Symlink created: $TMUX_TARGET -> $TMUX_SOURCE"
    fi

    if [ -f "$TMUX_LOCAL_SOURCE" ]; then
        if [ -L "$TMUX_LOCAL_TARGET" ]; then
            CURRENT_LOCAL_LINK="$(readlink "$TMUX_LOCAL_TARGET")"
            if [ "$CURRENT_LOCAL_LINK" = "$TMUX_LOCAL_SOURCE" ]; then
                echo "Symlink already correct: $TMUX_LOCAL_TARGET"
            else
                echo "Updating symlink: $TMUX_LOCAL_TARGET (was $CURRENT_LOCAL_LINK)"
                rm "$TMUX_LOCAL_TARGET"
                ln -s "$TMUX_LOCAL_SOURCE" "$TMUX_LOCAL_TARGET"
            fi
        else
            [ -e "$TMUX_LOCAL_TARGET" ] && mv "$TMUX_LOCAL_TARGET" "$TMUX_LOCAL_TARGET.bak.$(date +%Y%m%d%H%M%S)"
            ln -s "$TMUX_LOCAL_SOURCE" "$TMUX_LOCAL_TARGET"
            echo "Symlink created: $TMUX_LOCAL_TARGET -> $TMUX_LOCAL_SOURCE"
        fi
    fi
}

# =============================================
# tpm (tmux plugin manager)
# =============================================
install_tpm() {
    echo "=== Installing tpm ==="
    if [ -d "$HOME/.tmux/plugins/tpm" ]; then
        echo "tpm already installed."
    else
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
        echo "tpm installed."
    fi
    echo "tmux plugins will auto-install on next launch, or press prefix + I."
}

# =============================================
# Neovim image/LaTeX/mermaid tools (local only)
# On macOS/Arch, install tools for snacks.nvim image viewer.
# On Ubuntu (SSH remote), these are disabled in nvim config.
# =============================================
install_nvim_image_tools() {
    echo "=== Installing Neovim image/LaTeX/mermaid tools ==="
    case "$OS" in
        macos)
            BREW_TOOLS=""
            is_installed luarocks  || BREW_TOOLS="$BREW_TOOLS luarocks"
            is_installed magick   || BREW_TOOLS="$BREW_TOOLS imagemagick"
            is_installed tectonic || BREW_TOOLS="$BREW_TOOLS tectonic"
            if [ -n "$BREW_TOOLS" ]; then
                install_with_brew $BREW_TOOLS
            fi
            # mmdc (mermaid-cli) via npm
            if ! is_installed mmdc; then
                if is_installed npm; then
                    echo "  Installing mmdc (mermaid-cli) via npm (timeout: 120s)..."
                    if ! run_with_timeout 120 npm install -g --no-audit --no-fund @mermaid-js/mermaid-cli; then
                        ret=$?
                        if [ $ret -eq 124 ]; then
                            echo "  [!] npm install timed out after 120s. Network may be slow."
                            echo "  Try manually later: npm install -g @mermaid-js/mermaid-cli"
                        else
                            echo "  npm global install failed. Retrying with user prefix: $HOME/.local"
                            npm config set prefix "$HOME/.local"
                            if ! run_with_timeout 120 npm install -g --no-audit --no-fund @mermaid-js/mermaid-cli; then
                                echo "  [!] mmdc install failed. Skipping."
                            fi
                            case ":$PATH:" in
                                *":$HOME/.local/bin:"*) ;;
                                *) export PATH="$HOME/.local/bin:$PATH" ;;
                            esac
                        fi
                    fi
                else
                    echo "  [!] npm not found, skipping mmdc. Install Node.js first."
                fi
            else
                echo "  Already installed: mmdc"
            fi
            echo "  All image tools checked."
            ;;
        arch)
            PACMAN_TOOLS=""
            is_installed luarocks  || PACMAN_TOOLS="$PACMAN_TOOLS luarocks"
            is_installed magick   || PACMAN_TOOLS="$PACMAN_TOOLS imagemagick"
            is_installed tectonic || PACMAN_TOOLS="$PACMAN_TOOLS tectonic"
            if [ -n "$PACMAN_TOOLS" ]; then
                install_with_pacman $PACMAN_TOOLS
            fi
            if ! is_installed mmdc; then
                if is_installed npm; then
                    echo "  Installing mmdc (mermaid-cli) via npm (timeout: 120s)..."
                    if ! run_with_timeout 120 npm install -g --no-audit --no-fund @mermaid-js/mermaid-cli; then
                        ret=$?
                        if [ $ret -eq 124 ]; then
                            echo "  [!] npm install timed out after 120s. Network may be slow."
                            echo "  Try manually later: npm install -g @mermaid-js/mermaid-cli"
                        else
                            echo "  npm global install failed. Retrying with user prefix: $HOME/.local"
                            npm config set prefix "$HOME/.local"
                            if ! run_with_timeout 120 npm install -g --no-audit --no-fund @mermaid-js/mermaid-cli; then
                                echo "  [!] mmdc install failed. Skipping."
                            fi
                            case ":$PATH:" in
                                *":$HOME/.local/bin:"*) ;;
                                *) export PATH="$HOME/.local/bin:$PATH" ;;
                            esac
                        fi
                    fi
                else
                    echo "  [!] npm not found, skipping mmdc. Install Node.js first."
                fi
            else
                echo "  Already installed: mmdc"
            fi
            echo "  All image tools checked."
            ;;
        ubuntu)
            echo "  Skipping image tools on Ubuntu (disabled in nvim config for SSH remote)."
            ;;
    esac
}

# =============================================
# Shell integration
# =============================================
setup_shell_integration() {
    echo "=== Setting up shell integration ==="
    COMMON_SH="$HOME/.config/shell/common.sh"
    COMMON_FISH="$HOME/.config/shell/common.fish"

    # bash (interactive non-login shells)
    if [ -f "$HOME/.bashrc" ]; then
        if ! grep -qF "$COMMON_SH" "$HOME/.bashrc"; then
            printf '\n# dotfiles shared config\n[ -f "%s" ] && . "%s"\n' "$COMMON_SH" "$COMMON_SH" >> "$HOME/.bashrc"
            echo "  Added to ~/.bashrc"
        else
            echo "  Already present: ~/.bashrc"
        fi
    fi

    # bash login shells: ensure .bash_profile or .profile sources .bashrc
    # SSH sessions load .bash_profile (if exists) or .profile, skipping .bashrc
    BASHRC_SOURCE_LINE='[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"'
    if [ -f "$HOME/.bash_profile" ]; then
        if ! grep -qF '.bashrc' "$HOME/.bash_profile"; then
            printf '\n# Source .bashrc for login shells\n%s\n' "$BASHRC_SOURCE_LINE" >> "$HOME/.bash_profile"
            echo "  Added .bashrc sourcing to ~/.bash_profile"
        else
            echo "  Already present: ~/.bash_profile"
        fi
    elif [ -f "$HOME/.profile" ]; then
        if ! grep -qF '.bashrc' "$HOME/.profile"; then
            printf '\n# Source .bashrc for login shells\n%s\n' "$BASHRC_SOURCE_LINE" >> "$HOME/.profile"
            echo "  Added .bashrc sourcing to ~/.profile"
        else
            echo "  Already present: ~/.profile"
        fi
    fi

    # zsh
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -qF "$COMMON_SH" "$HOME/.zshrc"; then
            printf '\n# dotfiles shared config\n[ -f "%s" ] && . "%s"\n' "$COMMON_SH" "$COMMON_SH" >> "$HOME/.zshrc"
            echo "  Added to ~/.zshrc"
        else
            echo "  Already present: ~/.zshrc"
        fi
    fi

    # fish — only if fish is installed AND config already exists (don't create it)
    FISH_CONFIG="$HOME/.config/fish/config.fish"
    if command -v fish >/dev/null 2>&1 && [ -f "$FISH_CONFIG" ]; then
        if ! grep -qF "$COMMON_FISH" "$FISH_CONFIG"; then
            printf '\n# dotfiles shared config\ntest -f "%s" && source "%s"\n' "$COMMON_FISH" "$COMMON_FISH" >> "$FISH_CONFIG"
            echo "  Added to $FISH_CONFIG"
        else
            echo "  Already present: $FISH_CONFIG"
        fi
    fi
}

# =============================================
# Claude Code hooks
# Wires hook.sh into ~/.claude/settings.json for:
#   UserPromptSubmit, PreToolUse, PostToolUse, Stop, Notification
# hook.sh updates agent-status state files and shows popup notifications.
# =============================================
setup_claude_hooks() {
    echo "=== Setting up Claude Code hooks ==="

    if ! is_installed claude; then
        echo "  claude CLI not found — skipping hooks setup."
        return
    fi

    HOOK_SCRIPT="$HOME/.config/tmux/agent-status/hooks/hook.sh"

    if [ ! -f "$HOOK_SCRIPT" ]; then
        echo "  [!] Not found: $HOOK_SCRIPT — skipping hooks setup."
        return
    fi
    chmod +x "$HOOK_SCRIPT"

    if ! is_installed jq; then
        echo "  [!] jq not found — cannot write settings.json. Install jq first."
        return
    fi

    CLAUDE_SETTINGS="$HOME/.claude/settings.json"
    mkdir -p "$HOME/.claude"

    # Idempotency: skip only if hook.sh is already wired into PostToolUse
    # (PostToolUse was the last event added, so its presence implies all others)
    if [ -f "$CLAUDE_SETTINGS" ] \
        && jq -e --arg cmd "$HOOK_SCRIPT" \
            '[.hooks.PostToolUse[]?.hooks[]?.command] | index($cmd)' \
            "$CLAUDE_SETTINGS" >/dev/null 2>&1; then
        echo "  Hooks already configured: $CLAUDE_SETTINGS"
        return
    fi

    # Build the hook entry for our script (no matcher = all events)
    hook_entry="{\"hooks\": [{\"type\": \"command\", \"command\": \"$HOOK_SCRIPT\"}]}"

    if [ -f "$CLAUDE_SETTINGS" ]; then
        # Merge: append our hook to each event, deduplicating by command.
        # Uses append+dedup (not replace) to preserve hooks from other tools.
        jq --argjson entry "$hook_entry" '
            def add_hook(ev): .hooks[ev] = ((.hooks[ev] // []) + [$entry]
                                            | unique_by(.hooks[0].command));
            add_hook("UserPromptSubmit")
          | add_hook("PreToolUse")
          | add_hook("PostToolUse")
          | add_hook("Stop")
          | add_hook("Notification")
        ' "$CLAUDE_SETTINGS" > "$CLAUDE_SETTINGS.tmp" \
        && mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"
    else
        jq -n --argjson entry "$hook_entry" '{
            "hooks": {
                "UserPromptSubmit": [$entry],
                "PreToolUse":       [$entry],
                "PostToolUse":      [$entry],
                "Stop":             [$entry],
                "Notification":     [$entry]
            }
        }' > "$CLAUDE_SETTINGS"
    fi
    echo "  Hooks configured: $CLAUDE_SETTINGS"
}

# =============================================
# Main
# =============================================
detect_os
install_common_tools
install_ghostty_terminfo
install_yazi
install_yazi_plugins
install_ouch
configure_tmux
install_tpm
install_nvim_image_tools
setup_shell_integration
setup_claude_hooks

echo ""
echo "=== All done! ==="
