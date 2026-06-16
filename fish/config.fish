if status is-interactive
    # Commands to run in interactive sessions can go here
end

# dotfiles shared config
test -f "/home/admin/.config/shell/common.fish" && source "/home/admin/.config/shell/common.fish"

# dotfiles shared config
test -f "/Users/banma-3055/.config/shell/common.fish" && source "/Users/banma-3055/.config/shell/common.fish"
