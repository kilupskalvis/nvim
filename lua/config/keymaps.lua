-- Window navigation (also on LazyVim's <C-h>/<C-j>/<C-k>/<C-l>)
vim.keymap.set("n", "<leader>w<Left>", "<C-w>h", { desc = "Go to left window" })
vim.keymap.set("n", "<leader>w<Down>", "<C-w>j", { desc = "Go to lower window" })
vim.keymap.set("n", "<leader>w<Up>", "<C-w>k", { desc = "Go to upper window" })
vim.keymap.set("n", "<leader>w<Right>", "<C-w>l", { desc = "Go to right window" })
vim.keymap.set("n", "<leader>wh", "<C-w>h", { desc = "Go to left window" })
vim.keymap.set("n", "<leader>wj", "<C-w>j", { desc = "Go to lower window" })
vim.keymap.set("n", "<leader>wk", "<C-w>k", { desc = "Go to upper window" })
vim.keymap.set("n", "<leader>wl", "<C-w>l", { desc = "Go to right window" })

-- Directional splits, mirroring tmux's `prefix s` then a direction. Unlike
-- LazyVim's <leader>- / <leader>| these can place the new window left or above,
-- which 'splitright'/'splitbelow' otherwise prevent.
vim.keymap.set("n", "<leader>wsh", "<cmd>leftabove vsplit<cr>", { desc = "Split left" })
vim.keymap.set("n", "<leader>wsj", "<cmd>belowright split<cr>", { desc = "Split down" })
vim.keymap.set("n", "<leader>wsk", "<cmd>aboveleft split<cr>", { desc = "Split up" })
vim.keymap.set("n", "<leader>wsl", "<cmd>rightbelow vsplit<cr>", { desc = "Split right" })
vim.keymap.set("n", "<leader>ws<Left>", "<cmd>leftabove vsplit<cr>", { desc = "Split left" })
vim.keymap.set("n", "<leader>ws<Down>", "<cmd>belowright split<cr>", { desc = "Split down" })
vim.keymap.set("n", "<leader>ws<Up>", "<cmd>aboveleft split<cr>", { desc = "Split up" })
vim.keymap.set("n", "<leader>ws<Right>", "<cmd>rightbelow vsplit<cr>", { desc = "Split right" })

-- Move lines up/down
vim.keymap.set("n", "<A-Up>", "<cmd>m .-2<cr>==", { desc = "Move line up" })
vim.keymap.set("n", "<A-Down>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
vim.keymap.set("v", "<A-Up>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })
vim.keymap.set("v", "<A-Down>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })

-- Window resizing is provided by LazyVim on <C-Up>/<C-Down>/<C-Left>/<C-Right>.
-- Don't map it to <A-S-Arrow> here: <A-...> and <M-...> are the same key, so
-- those would collide with the <M-S-Arrow> motions further down.

-- Buffer management
vim.keymap.set("n", "<leader>d", function() Snacks.bufdelete() end, { desc = "Delete buffer", nowait = true })

-- Buffer navigation
vim.keymap.set("n", "<leader><Left>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader><Right>", "<cmd>bnext<cr>", { desc = "Next buffer" })

-- hjkl twins of the arrows above. This takes over LazyVim's <leader>l = :Lazy,
-- which is still reachable from the dashboard (`L`) and as `:Lazy`, so the only
-- thing lost is a shortcut to a plugin manager you open rarely.
vim.keymap.set("n", "<leader>h", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader>l", "<cmd>bnext<cr>", { desc = "Next buffer" })

-- Line start/end navigation. <M-S-h> normalises to <M-H>, which is a distinct
-- key from <M-h>, so the hjkl variants can sit alongside the arrows.
vim.keymap.set({ "n", "v" }, "<M-S-Left>", "^", { desc = "Start of line" })
vim.keymap.set({ "n", "v" }, "<M-S-Right>", "$", { desc = "End of line" })
vim.keymap.set({ "n", "v" }, "<M-H>", "^", { desc = "Start of line" })
vim.keymap.set({ "n", "v" }, "<M-L>", "$", { desc = "End of line" })
vim.keymap.set("i", "<M-S-Left>", "<C-o>^", { desc = "Start of line" })
vim.keymap.set("i", "<M-S-Right>", "<C-o>$", { desc = "End of line" })
vim.keymap.set("i", "<M-H>", "<C-o>^", { desc = "Start of line" })
vim.keymap.set("i", "<M-L>", "<C-o>$", { desc = "End of line" })

-- Top/bottom of file
vim.keymap.set({ "n", "v" }, "<M-S-Up>", "gg", { desc = "Top of file" })
vim.keymap.set({ "n", "v" }, "<M-S-Down>", "G", { desc = "Bottom of file" })
vim.keymap.set({ "n", "v" }, "<M-K>", "gg", { desc = "Top of file" })
vim.keymap.set({ "n", "v" }, "<M-J>", "G", { desc = "Bottom of file" })
vim.keymap.set("i", "<M-S-Up>", "<C-o>gg", { desc = "Top of file" })
vim.keymap.set("i", "<M-S-Down>", "<C-o>G", { desc = "Bottom of file" })
vim.keymap.set("i", "<M-K>", "<C-o>gg", { desc = "Top of file" })
vim.keymap.set("i", "<M-J>", "<C-o>G", { desc = "Bottom of file" })

-- Ctrl+Backspace deletes word back (like Ctrl+W)
vim.keymap.set("i", "<C-BS>", "<C-w>", { desc = "Delete word back" })

-- Make Ctrl+Z undo
vim.keymap.set("n", "<C-z>", "u", { noremap = true })

-- Suspend nvim to get the shell it was launched from; `fg` there brings it
-- back. <C-z> is undo above, so suspend needs its own key. Normal mode only:
-- insert-mode <C-t> is indent-one-shiftwidth and worth keeping. The only thing
-- lost is the normal-mode tag-stack pop, which <C-o> covers via the jumplist.
vim.keymap.set("n", "<C-t>", "<cmd>suspend<cr>", { desc = "Suspend (back to shell)" })

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
-- Note: don't delete keys that a plugin spec also claims. lazy.nvim registers
-- plugin `keys` at startup and this file runs later on VeryLazy, so deleting
-- <leader>gf here removed diffview's own File History binding, not LazyVim's.
pcall(vim.keymap.del, "n", "<leader>gg")
pcall(vim.keymap.del, "n", "<leader>gG")
pcall(vim.keymap.del, "n", "<leader>gL")
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

-- hjkl equivalent of Shift+Arrows. There is no distinct <S-j>/<S-k> key: Shift
-- on a letter just yields the uppercase letter, so this takes over J (join
-- lines) and K (LSP hover).
vim.keymap.set({ "n", "v" }, "J", "20j", { desc = "Move 20 lines down" })
vim.keymap.set({ "n", "v" }, "K", "20k", { desc = "Move 20 lines up" })

-- hjkl equivalent of <S-Left>/<S-Right>, which vim defines as b/w. Takes over
-- LazyVim's bufferline H/L (disabled in lua/plugins/keymaps.lua); buffer
-- cycling is still on [b / ]b and <leader><Left> / <leader><Right>.
vim.keymap.set({ "n", "v" }, "H", "b", { desc = "Previous word" })
vim.keymap.set({ "n", "v" }, "L", "w", { desc = "Next word" })

-- Hover moves off K. Two things map K to hover and both must be handled:
--   * LazyVim/snacks -- disabled via the `["*"].keys` entry in lua/plugins/lsp.lua
--     (it re-applies on a 100ms debounce, so deleting it after the fact loses).
--   * Neovim itself -- lsp.lua only sets K when no mapping exists yet
--     (`maparg('K') == ''`), and the LSP often attaches before this file loads,
--     so drop its buffer-local map below.
vim.keymap.set("n", "<leader>k", vim.lsp.buf.hover, { desc = "Hover" })
local function drop_default_hover_key(buf)
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(buf) then return end
    for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, "n")) do
      if map.lhs == "K" and map.desc == "vim.lsp.buf.hover()" then
        pcall(vim.keymap.del, "n", "K", { buffer = buf })
      end
    end
  end)
end
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args) drop_default_hover_key(args.buf) end,
})
-- Buffers an LSP already attached to before this file loaded get no LspAttach.
for _, client in ipairs(vim.lsp.get_clients()) do
  for buf in pairs(client.attached_buffers or {}) do
    drop_default_hover_key(buf)
  end
end

-- Tame Shift+Scroll to scroll 3 lines instead of a full page
vim.keymap.set({ "n", "i", "v" }, "<S-ScrollWheelUp>", "<C-y><C-y><C-y>", { desc = "Shift+Scroll Up (slow)" })
vim.keymap.set({ "n", "i", "v" }, "<S-ScrollWheelDown>", "<C-e><C-e><C-e>", { desc = "Shift+Scroll Down (slow)" })

-- Toggle comment with Ctrl+/ (terminals often send C-_ for C-/)
vim.keymap.set("v", "<C-/>", "gcgv", { remap = true, desc = "Toggle comment" })
vim.keymap.set("n", "<C-/>", "gcc", { remap = true, desc = "Toggle comment line" })
vim.keymap.set("v", "<C-_>", "gcgv", { remap = true, desc = "Toggle comment" })
vim.keymap.set("n", "<C-_>", "gcc", { remap = true, desc = "Toggle comment line" })

-- Indent/dedent with Tab/Shift+Tab
vim.keymap.set("v", "<Tab>", function() vim.cmd("silent! normal! >gv") end, { desc = "Indent selection" })
vim.keymap.set("v", "<S-Tab>", function() vim.cmd("silent! normal! <gv") end, { desc = "Dedent selection" })
vim.keymap.set("i", "<S-Tab>", "<C-d>", { desc = "Dedent line" })

-- Exit terminal mode
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Toggle dark/light mode
vim.keymap.set("n", "<leader>ut", "<cmd>CyberdreamToggleMode<cr>", { desc = "Toggle dark/light mode" })
