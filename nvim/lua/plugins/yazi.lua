return {
  {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    keys = {
      { "<leader>y", "<cmd>Yazi<cr>",     desc = "Open yazi (file dir)" },
      { "<leader>Y", "<cmd>Yazi cwd<cr>", desc = "Open yazi (cwd)" },
    },
    opts = {
      open_for_directories = true,
      floating_window_scaling_factor = 0.9,
    },
  },
}
