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
# Common tools
# =============================================

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
            echo "  [!] Auto-install not supported on Ubuntu (system packages may be outdated)."
            echo "  Please install the following manually (e.g. via Homebrew, cargo, or latest .deb):"
            echo "     $TOOLS_TO_INSTALL"
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
    echo "Yazi plugins done."
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
install_ghostty_terminfo
install_yazi
install_yazi_plugins
configure_tmux
install_tpm

echo ""
echo "=== All done! ==="
