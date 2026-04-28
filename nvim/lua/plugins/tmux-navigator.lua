return {
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate Left (tmux/nvim)" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Navigate Down (tmux/nvim)" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Navigate Up (tmux/nvim)" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate Right (tmux/nvim)" },
    },
  },
}
