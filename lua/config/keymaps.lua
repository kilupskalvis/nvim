-- Window navigation
vim.keymap.set("n", "<leader>w<Left>", "<C-w>h", { desc = "Go to left window" })
vim.keymap.set("n", "<leader>w<Down>", "<C-w>j", { desc = "Go to lower window" })
vim.keymap.set("n", "<leader>w<Up>", "<C-w>k", { desc = "Go to upper window" })
vim.keymap.set("n", "<leader>w<Right>", "<C-w>l", { desc = "Go to right window" })

-- Move lines up/down
vim.keymap.set("n", "<A-Up>", "<cmd>m .-2<cr>==", { desc = "Move line up" })
vim.keymap.set("n", "<A-Down>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
vim.keymap.set("v", "<A-Up>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })
vim.keymap.set("v", "<A-Down>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })

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

-- Line start/end navigation
vim.keymap.set({ "n", "v" }, "<M-S-Left>", "^", { desc = "Start of line" })
vim.keymap.set({ "n", "v" }, "<M-S-Right>", "$", { desc = "End of line" })
vim.keymap.set("i", "<M-S-Left>", "<C-o>^", { desc = "Start of line" })
vim.keymap.set("i", "<M-S-Right>", "<C-o>$", { desc = "End of line" })

-- Top/bottom of file
vim.keymap.set({ "n", "v" }, "<M-S-Up>", "gg", { desc = "Top of file" })
vim.keymap.set({ "n", "v" }, "<M-S-Down>", "G", { desc = "Bottom of file" })
vim.keymap.set("i", "<M-S-Up>", "<C-o>gg", { desc = "Top of file" })
vim.keymap.set("i", "<M-S-Down>", "<C-o>G", { desc = "Bottom of file" })

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

-- Remove LazyVim's git bindings (replaced by diffview + gitlineage + snacks.blame_line)
pcall(vim.keymap.del, "n", "<leader>gg")
pcall(vim.keymap.del, "n", "<leader>gG")
pcall(vim.keymap.del, "n", "<leader>gl")
pcall(vim.keymap.del, "n", "<leader>gL")
pcall(vim.keymap.del, "n", "<leader>gf")
pcall(vim.keymap.del, "n", "<leader>gb")

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

-- Tame Shift+Arrows to move 5 lines instead of a full page
vim.keymap.set({ "n", "v" }, "<S-Up>", "20<Up>", { desc = "Move 20 lines up" })
vim.keymap.set({ "n", "v" }, "<S-Down>", "20<Down>", { desc = "Move 20 lines down" })
vim.keymap.set("i", "<S-Up>", "<C-o>20<Up>", { desc = "Move 20 lines up" })
vim.keymap.set("i", "<S-Down>", "<C-o>20<Down>", { desc = "Move 20 lines down" })

-- Tame Shift+Scroll to scroll 3 lines instead of a full page
vim.keymap.set({ "n", "i", "v" }, "<S-ScrollWheelUp>", "<C-y><C-y><C-y>", { desc = "Shift+Scroll Up (slow)" })
vim.keymap.set({ "n", "i", "v" }, "<S-ScrollWheelDown>", "<C-e><C-e><C-e>", { desc = "Shift+Scroll Down (slow)" })

-- Toggle comment with Ctrl+/
vim.keymap.set("v", "<C-/>", "gcgv", { remap = true, desc = "Toggle comment" })
vim.keymap.set("n", "<C-/>", "gcc", { remap = true, desc = "Toggle comment line" })

-- Indent/dedent with Tab/Shift+Tab
vim.keymap.set("v", "<Tab>", function() vim.cmd("silent! normal! >gv") end, { desc = "Indent selection" })
vim.keymap.set("v", "<S-Tab>", function() vim.cmd("silent! normal! <gv") end, { desc = "Dedent selection" })
vim.keymap.set("i", "<S-Tab>", "<C-d>", { desc = "Dedent line" })

-- Exit terminal mode
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Toggle dark/light mode
vim.keymap.set("n", "<leader>ut", "<cmd>CyberdreamToggleMode<cr>", { desc = "Toggle dark/light mode" })
