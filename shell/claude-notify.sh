#!/bin/sh
# Claude Code notification hook - cross-platform
# Usage: claude-notify.sh <Stop|Notification>

TITLE="Claude Code"
case "$1" in
    Stop)         MESSAGE="任务已完成" ;;
    Notification) MESSAGE="需要您的确认或输入" ;;
    *)            MESSAGE="${1:-done}" ;;
esac

OS="$(uname -s)"

# macOS
if [ "$OS" = "Darwin" ]; then
    if command -v terminal-notifier >/dev/null 2>&1; then
        terminal-notifier -title "$TITLE" -message "$MESSAGE" -sound Glass
    else
        osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"Glass\""
    fi
    exit 0
fi

# Linux with desktop session
if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
    command -v notify-send >/dev/null 2>&1 && notify-send "$TITLE" "$MESSAGE"
    # Play sound
    for player in paplay aplay; do
        if command -v $player >/dev/null 2>&1; then
            $player /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null &
            break
        fi
    done
    exit 0
fi

# SSH / headless: bell travels through SSH → tmux → Ghostty
printf '\a'
