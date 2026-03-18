-- Window navigation
vim.keymap.set("n", "<leader>w<Left>", "<C-w>h", { desc = "Go to left window" })
vim.keymap.set("n", "<leader>w<Down>", "<C-w>j", { desc = "Go to lower window" })
vim.keymap.set("n", "<leader>w<Up>", "<C-w>k", { desc = "Go to upper window" })
vim.keymap.set("n", "<leader>w<Right>", "<C-w>l", { desc = "Go to right window" })

-- Window resizing
vim.keymap.set("n", "<A-S-Up>", "<cmd>resize +2<cr>", { desc = "Increase height" })
vim.keymap.set("n", "<A-S-Down>", "<cmd>resize -2<cr>", { desc = "Decrease height" })
vim.keymap.set("n", "<A-S-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease width" })
vim.keymap.set("n", "<A-S-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase width" })

-- Disable hjkl in regular file buffers
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    if vim.bo.buftype == "" and vim.bo.filetype ~= "oil" then
      local opts = { noremap = true, buffer = true, silent = true }
      vim.keymap.set("n", "h", "<Nop>", opts)
      vim.keymap.set("n", "j", "<Nop>", opts)
      vim.keymap.set("n", "k", "<Nop>", opts)
      vim.keymap.set("n", "l", "<Nop>", opts)
    end
  end,
})

-- Buffer management
vim.keymap.set("n", "<leader>d", function() Snacks.bufdelete() end, { desc = "Delete buffer", nowait = true })

-- Buffer navigation
vim.keymap.set("n", "<leader><Left>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader><Right>", "<cmd>bnext<cr>", { desc = "Next buffer" })

-- Make Ctrl+Z undo
vim.keymap.set("n", "<C-z>", "u", { noremap = true })

-- Make Ctrl+Y redo
vim.keymap.set("n", "<C-y>", "<C-r>", { noremap = true })

vim.api.nvim_create_user_command("Dashboard", function()
  require("snacks.dashboard").open()
end, {})

-- Claude Code
vim.keymap.set("n", "<leader>cc", function()
  Snacks.terminal("claude", { win = { position = "bottom" } })
end, { desc = "Claude Code (toggle)" })
vim.keymap.set("n", "<leader>cC", "<cmd>split | terminal claude<cr>", { desc = "Claude Code (new)" })

-- Remove LazyVim's lazygit log bindings (replaced by gitlineage.nvim)
vim.keymap.del("n", "<leader>gl")
vim.keymap.del("n", "<leader>gL")
-- Remove LazyVim's git file history binding (replaced by diffview)
vim.keymap.del("n", "<leader>gf")

-- Inline git blame (skip diffview buffers)
vim.keymap.set("n", "<leader>gb", function()
  local name = vim.api.nvim_buf_get_name(0)
  if name:match("^diffview://") then
    vim.notify("Git blame not available in diffview", vim.log.levels.WARN)
    return
  end
  Snacks.git.blame_line()
end, { desc = "Git Blame Line" })

vim.api.nvim_create_autocmd("CmdWinEnter", {
  callback = function() vim.cmd("quit") end,
})

-- Exit terminal mode
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
