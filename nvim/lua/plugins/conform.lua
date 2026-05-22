return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        c   = { "clang-format" },
        cpp = { "clang-format" },
        json = { "prettier" },
        jsonc = { "prettier" },
      },
    },
  },
}
