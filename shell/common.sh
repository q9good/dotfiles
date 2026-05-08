# Shared shell config for bash and zsh
# Sourced by ~/.bashrc or ~/.zshrc via install.sh

# Bell + popup notification when a long-running command finishes (>= threshold)
_NOTIFY_THRESHOLD=8
_NOTIFY_SHELL_SCRIPT="$HOME/.config/tmux/agent-status/scripts/notify-shell.sh"

_notify_bell() {
    local elapsed="${1:-0}"
    if [ -x "$_NOTIFY_SHELL_SCRIPT" ]; then
        "$_NOTIFY_SHELL_SCRIPT" "$elapsed"
    else
        # Fallback when plugin is not installed
        printf '\a'
        if [ -n "$TMUX" ]; then
            local win
            win="$(tmux display-message -p '#I:#W' 2>/dev/null)"
            tmux display-message "[$win] 命令完成"
        fi
    fi
}

if [ -n "$ZSH_VERSION" ]; then
    _notify_cmd_start=0
    _notify_preexec() { _notify_cmd_start=$SECONDS; }
    _notify_precmd() {
        if (( _notify_cmd_start > 0 )); then
            local elapsed=$(( SECONDS - _notify_cmd_start ))
            (( elapsed >= _NOTIFY_THRESHOLD )) && _notify_bell "$elapsed"
            _notify_cmd_start=0
        fi
    }
    autoload -Uz add-zsh-hook
    add-zsh-hook preexec _notify_preexec
    add-zsh-hook precmd  _notify_precmd

elif [ -n "$BASH_VERSION" ]; then
    _notify_cmd_start=0
    _notify_in_prompt=0
    _notify_preexec() {
        if (( _notify_in_prompt == 0 && _notify_cmd_start == 0 )); then
            _notify_cmd_start=$SECONDS
        fi
    }
    _notify_precmd() {
        _notify_in_prompt=1
        if (( _notify_cmd_start > 0 )); then
            local elapsed=$(( SECONDS - _notify_cmd_start ))
            (( elapsed >= _NOTIFY_THRESHOLD )) && _notify_bell "$elapsed"
            _notify_cmd_start=0
        fi
        _notify_in_prompt=0
    }
    trap '_notify_preexec' DEBUG
    PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }_notify_precmd"
fi
