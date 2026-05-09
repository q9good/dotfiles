# Shared shell config for fish
# Sourced by ~/.config/fish/config.fish via install.sh

set -g _NOTIFY_THRESHOLD 8
set -g _NOTIFY_SHELL_SCRIPT "$HOME/.config/tmux/agent-status/scripts/notify-shell.sh"
set -g _AS_SHELL_DIR "$HOME/.cache/agent-status/shell"
set -g _notify_cmd_start 0

function _notify_bell
    set elapsed $argv[1]
    if test -x $_NOTIFY_SHELL_SCRIPT
        $_NOTIFY_SHELL_SCRIPT $elapsed
    else
        printf '\a'
        if set -q TMUX
            set win (tmux display-message -p '#I:#W' 2>/dev/null)
            tmux display-message "[$win] 命令完成"
        end
    end
end

function _as_write_running
    set cmd $argv[1]
    if not set -q TMUX; or not set -q TMUX_PANE; return; end
    set sess (tmux display-message -p '#{session_name}' 2>/dev/null)
    test -z "$sess"; and return
    mkdir -p $_AS_SHELL_DIR
    set cmd_short (string sub -l 20 (string split ' ' $cmd)[1])
    printf '%s:%s\n' "$cmd_short" (date +%s) \
        > "$_AS_SHELL_DIR/${sess}_${TMUX_PANE}.running" 2>/dev/null
end

function _as_clear_running
    if not set -q TMUX; or not set -q TMUX_PANE; return; end
    set sess (tmux display-message -p '#{session_name}' 2>/dev/null)
    test -z "$sess"; and return
    rm -f "$_AS_SHELL_DIR/${sess}_${TMUX_PANE}.running" 2>/dev/null
end

function _notify_preexec --on-event fish_preexec
    set -g _notify_cmd_start (date +%s)
    _as_write_running $argv[1]
end

function _notify_postexec --on-event fish_postexec
    _as_clear_running
    if test $_notify_cmd_start -gt 0
        set elapsed (math (date +%s) - $_notify_cmd_start)
        if test $elapsed -ge $_NOTIFY_THRESHOLD
            _notify_bell $elapsed
        end
        set -g _notify_cmd_start 0
    end
end
