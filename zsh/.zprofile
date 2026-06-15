#
# Login shell configuration.
# Managed by dotfiles repo — do not edit directly; edit zsh/.zprofile in ~/.config.
#

# PATH additions (N = silently skip non-existent dirs)
path=($HOME/.local/bin(N) $path)
path=($HOME/.npm-global/bin(N) $path)

# Deduplicate path
typeset -gU cdpath fpath mailpath path

# Editor
export EDITOR='nvim'
export VISUAL='nvim'
export PAGER='less'

# Locale
export LANG='en_US.UTF-8'

# Less options: -R (color), -i (case-insensitive search), -M (long prompt), -S (chop long lines)
export LESS='-R -i -M -S'
