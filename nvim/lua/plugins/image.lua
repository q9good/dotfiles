-- Environment-aware plugin configuration.
-- SSH remote: disable image viewer, LaTeX rendering, and skip Mason-managed ruff.
-- Local (macOS/Arch): keep everything enabled.

local is_remote = vim.env.SSH_TTY ~= nil or vim.env.SSH_CONNECTION ~= nil

return {
  -- Disable snacks.nvim image module over SSH (no Kitty Graphics Protocol)
  {
    "folke/snacks.nvim",
    opts = {
      image = { enabled = not is_remote },
    },
  },

  -- Disable render-markdown.nvim LaTeX rendering over SSH (no tectonic/pdflatex)
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      latex = { enabled = not is_remote },
    },
  },

  -- Skip Mason-managed ruff install; use system ruff (pip install ruff) instead.
  -- Mason download can fail on restricted networks; system ruff is more reliable.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ruff = {
          mason = false,
        },
      },
    },
  },
}
