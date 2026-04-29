return {
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    init = function()
      -- Prevent the plugin from registering its own mappings;
      -- we set ours in config/keymaps.lua (loaded after LazyVim defaults).
      vim.g.tmux_navigator_no_mappings = 1
    end,
  },
}
