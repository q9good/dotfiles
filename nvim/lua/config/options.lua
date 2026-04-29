-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Use OSC 52 for clipboard (works over SSH without X11 forwarding).
-- Ghostty, iTerm2, kitty, tmux 3.3+ and most modern terminals support this.
-- NOTE: g:clipboard must be set here (before lazy.nvim init) so the provider
-- is registered early. But clipboard option is set in keymaps.lua (VeryLazy)
-- because LazyVim options.lua sets clipboard="" for SSH and would override us.
vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
    ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
  },
}
