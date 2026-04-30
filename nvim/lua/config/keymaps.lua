-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- vim-tmux-navigator: override LazyVim's C-h/j/k/l with TmuxNavigate commands.
-- pcall the del in case the mappings don't exist yet (e.g. headless mode).
for _, key in ipairs({ "<C-h>", "<C-j>", "<C-k>", "<C-l>" }) do
  pcall(vim.keymap.del, "n", key)
end
vim.keymap.set("n", "<C-h>", ":<C-U>TmuxNavigateLeft<CR>", { silent = true, desc = "Navigate Left (tmux/nvim)" })
vim.keymap.set("n", "<C-j>", ":<C-U>TmuxNavigateDown<CR>", { silent = true, desc = "Navigate Down (tmux/nvim)" })
vim.keymap.set("n", "<C-k>", ":<C-U>TmuxNavigateUp<CR>", { silent = true, desc = "Navigate Up (tmux/nvim)" })
vim.keymap.set("n", "<C-l>", ":<C-U>TmuxNavigateRight<CR>", { silent = true, desc = "Navigate Right (tmux/nvim)" })

-- Override vertical split: <leader>\ instead of <leader>| (consistent with tmux prefix + \)
vim.keymap.set("n", "<leader>\\", "<C-W>v", { desc = "Split Window Right", remap = true })
