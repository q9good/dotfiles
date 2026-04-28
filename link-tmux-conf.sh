#!/bin/sh
# Creates a symlink: ~/.tmux.conf -> <this_script_dir>/tmux/tmux.conf
#
# Compatible with bash, zsh, and fish:
#   bash link-tmux-conf.sh
#   zsh  link-tmux-conf.sh
#   fish link-tmux-conf.sh   (fish honors the shebang and delegates to /bin/sh)
#   ./link-tmux-conf.sh      (uses shebang)

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
