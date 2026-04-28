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

# =============================================
# Common tools: lazygit, fzf, ripgrep, fd, ghostty
# Only auto-installed on macOS and Arch Linux.
# On Ubuntu/Debian, these often require manual compilation.
# =============================================
install_common_tools() {
    echo "=== Installing common tools ==="

    case "$OS" in
        macos)
            TOOLS_TO_INSTALL=""
            is_installed lazygit  || TOOLS_TO_INSTALL="$TOOLS_TO_INSTALL lazygit"
            is_installed fzf      || TOOLS_TO_INSTALL="$TOOLS_TO_INSTALL fzf"
            is_installed rg       || TOOLS_TO_INSTALL="$TOOLS_TO_INSTALL ripgrep"
            is_installed fd       || TOOLS_TO_INSTALL="$TOOLS_TO_INSTALL fd"
            is_installed ghostty  || TOOLS_TO_INSTALL="$TOOLS_TO_INSTALL ghostty"
            if [ -n "$TOOLS_TO_INSTALL" ]; then
                install_with_brew $TOOLS_TO_INSTALL
            else
                echo "All common tools already installed."
            fi
            ;;
        arch)
            TOOLS_TO_INSTALL=""
            is_installed lazygit  || TOOLS_TO_INSTALL="$TOOLS_TO_INSTALL lazygit"
            is_installed fzf      || TOOLS_TO_INSTALL="$TOOLS_TO_INSTALL fzf"
            is_installed rg       || TOOLS_TO_INSTALL="$TOOLS_TO_INSTALL ripgrep"
            is_installed fd       || TOOLS_TO_INSTALL="$TOOLS_TO_INSTALL fd"
            is_installed ghostty  || TOOLS_TO_INSTALL="$TOOLS_TO_INSTALL ghostty"
            if [ -n "$TOOLS_TO_INSTALL" ]; then
                install_with_pacman $TOOLS_TO_INSTALL
            else
                echo "All common tools already installed."
            fi
            ;;
        ubuntu|linux-unknown)
            echo ""
            echo "  [!] Ubuntu/Debian detected."
            echo "  The following tools may need manual compilation or newer repos:"
            echo "    - lazygit   : https://github.com/jesseduffield/lazygit#installation"
            echo "    - fzf       : https://github.com/junegunn/fzf#installation"
            echo "    - ripgrep   : https://github.com/BurntSushi/ripgrep#installation"
            echo "    - fd        : https://github.com/sharkdp/fd#installation"
            echo "    - ghostty   : https://github.com/ghostty-org/ghostty"
            echo "  Please install them manually for your distribution version."
            echo ""
            ;;
    esac
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
    "$YA_CMD" pkg add yazi-rs/plugins:smart-enter
    "$YA_CMD" pkg add yazi-rs/plugins:full-border
    "$YA_CMD" pkg add yazi-rs/plugins:toggle-pane
    "$YA_CMD" pkg add yazi-rs/plugins:jump-to-char
    "$YA_CMD" pkg add yazi-rs/plugins:git
    "$YA_CMD" pkg add yazi-rs/plugins:smart-filter
    "$YA_CMD" pkg add yazi-rs/plugins:chmod
    "$YA_CMD" pkg add yazi-rs/plugins:smart-paste
    "$YA_CMD" pkg add yazi-rs/plugins:diff
    "$YA_CMD" pkg add yazi-rs/plugins:mime-ext
    echo "Yazi plugins installed."
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
        if [ ! -f "$TMUX_LOCAL_TARGET" ]; then
            cp "$TMUX_LOCAL_SOURCE" "$TMUX_LOCAL_TARGET"
            echo "Copied: $TMUX_LOCAL_TARGET"
        else
            echo "Local config already exists: $TMUX_LOCAL_TARGET (skipped)"
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
# Main
# =============================================
detect_os
install_common_tools
install_yazi
install_yazi_plugins
configure_tmux
install_tpm

echo ""
echo "=== All done! ==="
