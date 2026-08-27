# Shared shell config for bash and zsh
# Sourced by ~/.bashrc or ~/.zshrc via install.sh

_NOTIFY_THRESHOLD=8
_NOTIFY_SHELL_SCRIPT="$HOME/.config/tmux/agent-status/scripts/notify-shell.sh"
_AS_SHELL_DIR="$HOME/.cache/agent-status/shell"

_notify_bell() {
    local elapsed="${1:-0}"
    if [ -x "$_NOTIFY_SHELL_SCRIPT" ]; then
        "$_NOTIFY_SHELL_SCRIPT" "$elapsed"
    else
        printf '\a'
        if [ -n "$TMUX" ]; then
            local win
            win="$(tmux display-message -p '#I:#W' 2>/dev/null)"
            tmux display-message "[$win] 命令完成"
        fi
    fi
}

_as_write_running() {
    local cmd="$1"
    [ -z "${TMUX:-}" ] || [ -z "${TMUX_PANE:-}" ] && return
    # Skip internal hook functions (zoxide's __zoxide_hook etc.) that fire via
    # PROMPT_COMMAND/DEBUG — they're not real user commands and otherwise get
    # recorded as "running" forever in long-lived (e.g. TUI) panes.
    case "$cmd" in __zoxide_*) return;; esac
    local sess
    sess=$(tmux display-message -p '#{session_name}' 2>/dev/null) || return
    mkdir -p "$_AS_SHELL_DIR"
    # shell:cmd:start_ts  (cmd truncated to 20 chars, first word only)
    local cmd_short="${cmd%% *}"; cmd_short="${cmd_short:0:20}"
    local shell_type="bash"
    [ -n "$ZSH_VERSION" ] && shell_type="zsh"
    printf '%s:%s:%s\n' "$shell_type" "$cmd_short" "$(date +%s)" \
        > "$_AS_SHELL_DIR/${sess}_${TMUX_PANE}.running" 2>/dev/null
}

_as_clear_running() {
    [ -z "${TMUX:-}" ] || [ -z "${TMUX_PANE:-}" ] && return
    local sess
    sess=$(tmux display-message -p '#{session_name}' 2>/dev/null) || return
    rm -f "$_AS_SHELL_DIR/${sess}_${TMUX_PANE}.running" 2>/dev/null
}

if [ -n "$ZSH_VERSION" ]; then
    _notify_cmd_start=0
    _notify_preexec() {
        _notify_cmd_start=$SECONDS
        _as_write_running "$1"
    }
    _notify_precmd() {
        _as_clear_running
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
            _as_write_running "${BASH_COMMAND}"
        fi
    }
    _notify_precmd() {
        _notify_in_prompt=1
        _as_clear_running
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
