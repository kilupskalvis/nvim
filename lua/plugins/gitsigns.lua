-- gitsigns: gutter marks for added/changed/deleted lines against the index,
-- hunk navigation and staging, inline blame. Replaces the mini.diff extra.
-- Also the data source for the git section of the statusline later.
require("gitsigns").setup({
  signs = {
    add = { text = "▎" },
    change = { text = "▎" },
    delete = { text = "" },
    topdelete = { text = "" },
    changedelete = { text = "▎" },
    untracked = { text = "▎" },
  },
  signs_staged = {
    add = { text = "▎" },
    change = { text = "▎" },
    delete = { text = "" },
    topdelete = { text = "" },
    changedelete = { text = "▎" },
  },
  -- Buffer-local keys, set when gitsigns attaches (tracked files only).
  -- Hunk operations live under <leader>gk ("hunk"); <leader>gh is the
  -- whole-repo history in diffview and must stay a complete mapping.
  on_attach = function(buffer)
    local gs = require("gitsigns")
    local function map(mode, l, r, desc)
      vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc, silent = true })
    end
    -- In a diff window (diffview, :diffthis) ]c/[c are Vim's own hunk jumps.
    map("n", "]h", function()
      if vim.wo.diff then vim.cmd.normal({ "]c", bang = true }) else gs.nav_hunk("next") end
    end, "Next hunk")
    map("n", "[h", function()
      if vim.wo.diff then vim.cmd.normal({ "[c", bang = true }) else gs.nav_hunk("prev") end
    end, "Prev hunk")
    map("n", "]H", function() gs.nav_hunk("last") end, "Last hunk")
    map("n", "[H", function() gs.nav_hunk("first") end, "First hunk")
    map({ "n", "x" }, "<leader>gks", ":Gitsigns stage_hunk<CR>", "Stage hunk")
    map({ "n", "x" }, "<leader>gkr", ":Gitsigns reset_hunk<CR>", "Reset hunk")
    map("n", "<leader>gkS", gs.stage_buffer, "Stage buffer")
    map("n", "<leader>gku", gs.undo_stage_hunk, "Undo stage hunk")
    map("n", "<leader>gkR", gs.reset_buffer, "Reset buffer")
    map("n", "<leader>gkp", gs.preview_hunk_inline, "Preview hunk inline")
    map("n", "<leader>gkb", function() gs.blame_line({ full = true }) end, "Blame line (full)")
    map("n", "<leader>gkB", function() gs.blame() end, "Blame buffer")
    map("n", "<leader>gkd", gs.diffthis, "Diff this")
    map("n", "<leader>gkD", function() gs.diffthis("~") end, "Diff this ~")
    map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select hunk")
  end,
})

vim.keymap.set("n", "<leader>ug", "<cmd>Gitsigns toggle_signs<cr>", { desc = "Toggle git signs" })
