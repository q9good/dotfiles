# Shared shell config for bash and zsh
# Sourced by ~/.bashrc or ~/.zshrc via install.sh

# Bell notification when a long-running command finishes (>=10s)
_NOTIFY_THRESHOLD=8

if [ -n "$ZSH_VERSION" ]; then
    _notify_cmd_start=0
    _notify_preexec() { _notify_cmd_start=$SECONDS; }
    _notify_precmd() {
        if (( _notify_cmd_start > 0 )); then
            (( SECONDS - _notify_cmd_start >= _NOTIFY_THRESHOLD )) && printf '\a'
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
        # Only record the first subcommand's start time; skip if inside PROMPT_COMMAND
        if (( _notify_in_prompt == 0 && _notify_cmd_start == 0 )); then
            _notify_cmd_start=$SECONDS
        fi
    }
    _notify_precmd() {
        _notify_in_prompt=1
        if (( _notify_cmd_start > 0 )); then
            (( SECONDS - _notify_cmd_start >= _NOTIFY_THRESHOLD )) && printf '\a'
            _notify_cmd_start=0
        fi
        _notify_in_prompt=0
    }
    trap '_notify_preexec' DEBUG
    PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }_notify_precmd"
fi
