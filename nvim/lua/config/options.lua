-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Use OSC 52 for clipboard (works over SSH without X11 forwarding).
-- Ghostty, iTerm2, kitty, tmux 3.3+ and most modern terminals support this.
--
-- Both g:clipboard (provider) and opt.clipboard (sync mode) must be set here.
-- LazyVim defers clipboard: it caches opt.clipboard after loading config.options,
-- clears it during init, then restores the cached value during VeryLazy.
-- So setting it here ensures the cached value is "unnamedplus", not "".
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
vim.opt.clipboard = "unnamedplus"
