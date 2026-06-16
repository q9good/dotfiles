#
# Zsh interactive shell configuration.
# Managed by dotfiles repo — do not edit directly; edit zsh/.zshrc in ~/.config.
#

# Homebrew mirrors (BFSU)
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.bfsu.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.bfsu.edu.cn/git/homebrew/homebrew-core.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.bfsu.edu.cn/homebrew-bottles"
export HOMEBREW_API_DOMAIN="https://mirrors.bfsu.edu.cn/homebrew-bottles/api"

# Homebrew (Apple Silicon)
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Rust / Cargo
. "$HOME/.cargo/env"

# ~/.local/bin (uv, pipx, etc.)
. "$HOME/.local/bin/env"

# npm global packages
export PATH="$HOME/.npm-global/bin:$PATH"

# Source Prezto
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
    source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

#
# Aliases
#

# Gerrit code review push
alias commit="git push origin HEAD:refs/for/master"
alias gerrit="git push origin dev_dds_deliver:refs/for/dev_dds_deliver"

# vim always means nvim
alias vim='nvim'

# macOS-specific aliases
if [[ "$OSTYPE" == darwin* ]]; then
    alias ofd='open .'
    alias ql='qlmanage -p "$@" >& /dev/null'
    alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
fi

#
# jenv (lazy-loaded for faster startup)
#

if [ -d "$HOME/.jenv" ]; then
    export PATH="$HOME/.jenv/bin:$PATH"
    jenv() {
        unfunction jenv
        eval "$(command jenv init -)"
        jenv "$@"
    }
fi

#
# zoxide (smart cd replacement)
#

if (( $+commands[zoxide] )); then
    eval "$(zoxide init zsh)"
fi

#
# fzf integration (Ctrl+R history, Ctrl+T file search, Alt+C cd)
#

if (( $+commands[fzf] )); then
    source <(fzf --zsh)
fi

#
# Dotfiles shared config (tmux agent-status notification hooks)
#

[ -f "$HOME/.config/shell/common.sh" ] && . "$HOME/.config/shell/common.sh"
