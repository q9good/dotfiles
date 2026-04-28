#yazi, tmux, lazygit, fzf, ripgrep, fd 
# 下载 musl 静态链接版本
curl -fLo yazi.zip https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-musl.zip
unzip yazi.zip
# 将二进制文件移到 PATH 中
mv yazi-x86_64-unknown-linux-musl/yazi ~/.local/bin/yazi
rm -rf yazi.zip yazi-x86_64-unknown-linux-musl

#!/bin/sh
# Polyglot script: works in bash, zsh, and fish.
# Creates a symlink: ~/.tmux.conf -> <this_script_dir>/tmux/tmux.conf
#
# Usage (any shell):
#   bash auto_config.sh
#   zsh  auto_config.sh
#   fish auto_config.sh

# --- polyglot trick: the next line is valid in sh/bash/zsh and fish ---
true && true; or exec sh "$0" "$argv"
# In fish: `true` succeeds, so `or` is skipped — but fish parses it fine.
# In bash/zsh: `true && true` succeeds, `or` is never reached as a command
#              because `;` already terminated the statement... but `or` would
#              still be invoked. We need a different approach.
#
# Actually, let's use a clean polyglot:

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE="$SCRIPT_DIR/tmux/tmux.conf"
TARGET="$HOME/.tmux.conf"

if [ ! -f "$SOURCE" ]; then
    echo "Error: source file not found: $SOURCE"
    exit 1
fi

if [ -L "$TARGET" ]; then
    CURRENT_LINK="$(readlink "$TARGET")"
    if [ "$CURRENT_LINK" = "$SOURCE" ]; then
        echo "Symlink already exists and points to the correct target."
        echo "  $TARGET -> $SOURCE"
        exit 0
    fi
    echo "Removing existing symlink: $TARGET -> $CURRENT_LINK"
    rm "$TARGET"
elif [ -e "$TARGET" ]; then
    BACKUP="$TARGET.bak.$(date +%Y%m%d%H%M%S)"
    echo "Backing up existing file: $TARGET -> $BACKUP"
    mv "$TARGET" "$BACKUP"
fi

ln -s "$SOURCE" "$TARGET"
echo "Symlink created successfully:"
echo "  $TARGET -> $SOURCE"
