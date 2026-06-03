if status is-interactive
    # Commands to run in interactive sessions can go here
end

# dotfiles shared config
test -f "/home/admin/.config/shell/common.fish" && source "/home/admin/.config/shell/common.fish"

# dotfiles shared config
test -f "/home/wangzhichao.wzc/.config/shell/common.fish" && source "/home/wangzhichao.wzc/.config/shell/common.fish"
