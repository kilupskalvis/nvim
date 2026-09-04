-- vim.keymap.set(mode, lhs, rhs, opts)
--   mode: "n" normal, "i" insert, "v" visual+select, "x" visual only,
--         "o" operator-pending, "t" terminal, or a list of them.
--   lhs:  the keys you press. <leader> expands to vim.g.mapleader (Space).
--   rhs:  keys to feed, or a Lua function. "<cmd>...<cr>" runs an Ex command
--         without leaving the current mode.
--   opts: desc shows in :map and pickers; remap = true lets rhs trigger other
--         mappings (default is noremap); expr = true means rhs is an expression
--         whose result is the keys to feed; silent hides the command echo.
local map = vim.keymap.set

-- Movement --------------------------------------------------------------

-- j/k move by screen line on wrapped text, unless given a count (5j is 5
-- real lines). Arrows the same.
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Down" })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Up" })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Down" })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Up" })

-- Shift+Arrows move 20 lines instead of a page.
map({ "n", "v" }, "<S-Up>", "20<Up>", { desc = "Move 20 lines up" })
map({ "n", "v" }, "<S-Down>", "20<Down>", { desc = "Move 20 lines down" })
map("i", "<S-Up>", "<C-o>20<Up>", { desc = "Move 20 lines up" })
map("i", "<S-Down>", "<C-o>20<Down>", { desc = "Move 20 lines down" })

-- hjkl twins of Shift+Arrows. Shift on a letter is just the uppercase letter,
-- so this takes over J (join lines) and K (keyword lookup / LSP hover; hover
-- lives on <leader>k below). Because K is mapped here at startup, Neovim's
-- LSP does not install its own buffer-local K on attach.
map({ "n", "v" }, "J", "20j", { desc = "Move 20 lines down" })
map({ "n", "v" }, "K", "20k", { desc = "Move 20 lines up" })

-- hjkl twins of Shift+Left/Right, which Vim defines as b/w.
map({ "n", "v" }, "H", "b", { desc = "Previous word" })
map({ "n", "v" }, "L", "w", { desc = "Next word" })

-- Line start/end. <M-S-h> normalises to <M-H>, distinct from <M-h>, so the
-- hjkl variants sit alongside the arrows. <C-o> in insert mode runs one
-- normal-mode command and returns.
map({ "n", "v" }, "<M-S-Left>", "^", { desc = "Start of line" })
map({ "n", "v" }, "<M-S-Right>", "$", { desc = "End of line" })
map({ "n", "v" }, "<M-H>", "^", { desc = "Start of line" })
map({ "n", "v" }, "<M-L>", "$", { desc = "End of line" })
map("i", "<M-S-Left>", "<C-o>^", { desc = "Start of line" })
map("i", "<M-S-Right>", "<C-o>$", { desc = "End of line" })
map("i", "<M-H>", "<C-o>^", { desc = "Start of line" })
map("i", "<M-L>", "<C-o>$", { desc = "End of line" })

-- Top/bottom of file.
map({ "n", "v" }, "<M-S-Up>", "gg", { desc = "Top of file" })
map({ "n", "v" }, "<M-S-Down>", "G", { desc = "Bottom of file" })
map({ "n", "v" }, "<M-K>", "gg", { desc = "Top of file" })
map({ "n", "v" }, "<M-J>", "G", { desc = "Bottom of file" })
map("i", "<M-S-Up>", "<C-o>gg", { desc = "Top of file" })
map("i", "<M-S-Down>", "<C-o>G", { desc = "Bottom of file" })
map("i", "<M-K>", "<C-o>gg", { desc = "Top of file" })
map("i", "<M-J>", "<C-o>G", { desc = "Bottom of file" })

-- Shift+Scroll scrolls 3 lines instead of a page.
map({ "n", "i", "v" }, "<S-ScrollWheelUp>", "<C-y><C-y><C-y>", { desc = "Scroll up (slow)" })
map({ "n", "i", "v" }, "<S-ScrollWheelDown>", "<C-e><C-e><C-e>", { desc = "Scroll down (slow)" })

-- Search -----------------------------------------------------------------

-- n always goes forward and N backward, whether the search started with /
-- or ?. v:searchforward is 1 after /, 0 after ?. zv opens folds at the match.
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next search result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev search result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev search result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev search result" })

-- Esc also clears search highlighting. In insert mode it still leaves insert.
-- Normal-mode Esc is defined in plugins/editing.lua (multicursor first, then noh).
map({ "i", "s" }, "<esc>", function()
  vim.cmd("noh")
  return "<esc>"
end, { expr = true, desc = "Escape and clear hlsearch" })

-- Editing ----------------------------------------------------------------

-- Move lines. == re-indents the moved line; gv=gv re-selects and re-indents.
map("n", "<A-Up>", "<cmd>m .-2<cr>==", { desc = "Move line up" })
map("n", "<A-Down>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
map("v", "<A-Up>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })
map("v", "<A-Down>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })

-- Indent/dedent with Tab. silent! swallows the error on an empty selection.
map("v", "<Tab>", function() vim.cmd("silent! normal! >gv") end, { desc = "Indent selection" })
map("v", "<S-Tab>", function() vim.cmd("silent! normal! <gv") end, { desc = "Dedent selection" })
map("i", "<S-Tab>", "<C-d>", { desc = "Dedent line" })
-- < and > keep the selection so you can repeat them.
map("x", "<", "<gv")
map("x", ">", ">gv")

-- Toggle comment with Ctrl+/. Terminals often send C-_ for C-/, so both.
-- gc is Neovim's built-in comment operator; remap = true lets it trigger.
map("v", "<C-/>", "gcgv", { remap = true, desc = "Toggle comment" })
map("n", "<C-/>", "gcc", { remap = true, desc = "Toggle comment line" })
map("v", "<C-_>", "gcgv", { remap = true, desc = "Toggle comment" })
map("n", "<C-_>", "gcc", { remap = true, desc = "Toggle comment line" })
-- Open a commented line below/above and start typing in it.
map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add comment below" })
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add comment above" })

-- Undo break points: undo stops at punctuation instead of the whole insert.
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- Ctrl+Backspace deletes the word before the cursor, like Ctrl+W.
map("i", "<C-BS>", "<C-w>", { desc = "Delete word back" })

-- Ctrl+Z undo, Ctrl+Y redo, as everywhere else.
map("n", "<C-z>", "u", { desc = "Undo" })
map("n", "<C-y>", "<C-r>", { desc = "Redo" })

-- Save from any mode.
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

-- Suspend to the shell that launched nvim; `fg` there brings it back. Normal
-- mode only: insert-mode <C-t> is indent-one-shiftwidth and worth keeping.
map("n", "<C-t>", "<cmd>suspend<cr>", { desc = "Suspend (back to shell)" })

-- Windows ----------------------------------------------------------------

map("n", "<C-h>", "<C-w>h", { desc = "Go to left window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window", remap = true })
map("n", "<leader>w<Left>", "<C-w>h", { desc = "Go to left window" })
map("n", "<leader>w<Down>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<leader>w<Up>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<leader>w<Right>", "<C-w>l", { desc = "Go to right window" })
map("n", "<leader>wh", "<C-w>h", { desc = "Go to left window" })
map("n", "<leader>wj", "<C-w>j", { desc = "Go to lower window" })
map("n", "<leader>wk", "<C-w>k", { desc = "Go to upper window" })
map("n", "<leader>wl", "<C-w>l", { desc = "Go to right window" })
map("n", "<leader>wd", "<C-w>c", { desc = "Close window" })

-- Directional splits, mirroring tmux's `prefix s` then a direction. The
-- modifiers override 'splitright'/'splitbelow' so left and above are possible.
map("n", "<leader>wsh", "<cmd>leftabove vsplit<cr>", { desc = "Split left" })
map("n", "<leader>wsj", "<cmd>belowright split<cr>", { desc = "Split down" })
map("n", "<leader>wsk", "<cmd>aboveleft split<cr>", { desc = "Split up" })
map("n", "<leader>wsl", "<cmd>rightbelow vsplit<cr>", { desc = "Split right" })
map("n", "<leader>ws<Left>", "<cmd>leftabove vsplit<cr>", { desc = "Split left" })
map("n", "<leader>ws<Down>", "<cmd>belowright split<cr>", { desc = "Split down" })
map("n", "<leader>ws<Up>", "<cmd>aboveleft split<cr>", { desc = "Split up" })
map("n", "<leader>ws<Right>", "<cmd>rightbelow vsplit<cr>", { desc = "Split right" })

-- Resize. Not on <A-S-Arrow>: <A-...> and <M-...> are the same key and those
-- are the line motions above.
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- Buffers ----------------------------------------------------------------

map("n", "<leader><Left>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "<leader><Right>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>h", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "<leader>l", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to other buffer" })

-- Delete the buffer but keep the window: every window showing it switches to
-- another listed buffer first. Plain :bdelete closes the window too. Asks
-- before dropping unsaved changes. Replaces Snacks.bufdelete.
local function bufdelete(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if vim.bo[buf].modified then
    local choice = vim.fn.confirm(("Save changes to %q?"):format(vim.fn.bufname(buf)), "&Yes\n&No\n&Cancel")
    if choice == 0 or choice == 3 then return end
    if choice == 1 then vim.api.nvim_buf_call(buf, function() vim.cmd("write") end) end
  end
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.api.nvim_win_call(win, function()
      if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_buf(win) ~= buf then return end
      -- Prefer the alternate buffer, then any other listed buffer, else a new one.
      local alt = vim.fn.bufnr("#")
      if alt ~= buf and vim.fn.buflisted(alt) == 1 then
        vim.api.nvim_win_set_buf(win, alt)
        return
      end
      for _, other in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
        if other.bufnr ~= buf then
          vim.api.nvim_win_set_buf(win, other.bufnr)
          return
        end
      end
      vim.cmd("enew")
    end)
  end
  if vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.cmd, "bdelete! " .. buf)
  end
end
map("n", "<leader>d", bufdelete, { desc = "Delete buffer", nowait = true })
map("n", "<leader>bd", bufdelete, { desc = "Delete buffer" })
map("n", "<leader>bo", function()
  local cur = vim.api.nvim_get_current_buf()
  for _, b in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if b.bufnr ~= cur then bufdelete(b.bufnr) end
  end
end, { desc = "Delete other buffers" })
map("n", "<leader>bD", "<cmd>bd<cr>", { desc = "Delete buffer and window" })
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New file" })

-- Tabs -------------------------------------------------------------------

map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New tab" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close tab" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next tab" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous tab" })
map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close other tabs" })

-- Quickfix and location list -------------------------------------------

map("n", "<leader>xq", "<cmd>copen<cr>", { desc = "Quickfix list" })
map("n", "<leader>xl", "<cmd>lopen<cr>", { desc = "Location list" })
map("n", "[q", vim.cmd.cprev, { desc = "Previous quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next quickfix" })

-- Diagnostics and LSP ---------------------------------------------------
-- These use built-in Neovim functions and work as soon as a server attaches.
-- Per-server setup comes in the LSP step; the keys live here so they are
-- global rather than re-declared per buffer.

map("n", "<leader>k", vim.lsp.buf.hover, { desc = "Hover" })
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
local function diagnostic_goto(next, severity)
  return function()
    vim.diagnostic.jump({
      count = next and 1 or -1,
      float = true,
      severity = severity and vim.diagnostic.severity[severity] or nil,
    })
  end
end
map("n", "]d", diagnostic_goto(true), { desc = "Next diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Prev diagnostic" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev warning" })

-- Terminal ---------------------------------------------------------------

map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
-- Claude Code in a bottom split. The toggle version comes with the terminal
-- helper later; this always opens a new one.
map("n", "<leader>cC", "<cmd>botright split | terminal claude<cr>", { desc = "Claude Code (new)" })

-- Misc -------------------------------------------------------------------

map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })
map("n", "<leader>ui", vim.show_pos, { desc = "Inspect position (highlights)" })
map("n", "<leader>uI", function()
  vim.treesitter.inspect_tree()
  vim.api.nvim_input("I")
end, { desc = "Inspect treesitter tree" })
map("n", "<leader>uw", function()
  vim.wo.wrap = not vim.wo.wrap
end, { desc = "Toggle wrap" })
map("n", "<leader>us", function()
  vim.wo.spell = not vim.wo.spell
end, { desc = "Toggle spell" })

-- Filled in by later steps, kept here so the key list stays in one place:
--   <leader>cc  Claude Code toggle       (terminal helper)
--   <leader>gb  git blame line           (gitsigns, step 8)
--   <leader>ut  toggle dark/light        (colorscheme, step 3)
--   <leader>e   file explorer            (oil, step 10)
--   <leader>/ <leader>ff <leader>sg ...  picker (step 7)
