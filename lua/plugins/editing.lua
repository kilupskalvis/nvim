-- Editing helpers. Small plugins, one section each.
local map = vim.keymap.set

-- flash: jump anywhere on screen ----------------------------------------
-- s + two characters labels every match; press the label. S selects a
-- treesitter node around the cursor, growing with each press.
require("flash").setup({
  jump = {
    -- Feed the jump into search history and the search register so `n`
    -- repeats it. Costs: `s` overwrites the last `/` pattern.
    history = true,
    register = true,
    -- keep hlsearch after the jump so it is visible that `n` has somewhere to go
    nohlsearch = false,
  },
})
map({ "n", "x", "o" }, "s", function() require("flash").jump() end, { desc = "Flash" })
map({ "n", "x", "o" }, "S", function() require("flash").treesitter() end, { desc = "Flash treesitter" })
map("o", "r", function() require("flash").remote() end, { desc = "Remote flash" })
map({ "o", "x" }, "R", function() require("flash").treesitter_search() end, { desc = "Treesitter search" })
map("c", "<C-s>", function() require("flash").toggle() end, { desc = "Toggle flash search" })

-- yanky: yank history ------------------------------------------------------
-- After a put, [y / ]y swap in earlier yanks. History persists in shada.
require("yanky").setup({
  ring = { storage = "shada" },
  highlight = { timer = 150 },
})
map({ "n", "x" }, "y", "<Plug>(YankyYank)", { desc = "Yank" })
map({ "n", "x" }, "p", "<Plug>(YankyPutAfter)", { desc = "Put after" })
map({ "n", "x" }, "P", "<Plug>(YankyPutBefore)", { desc = "Put before" })
map({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)", { desc = "Put after, cursor after text" })
map({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)", { desc = "Put before, cursor after text" })
map("n", "[y", "<Plug>(YankyCycleForward)", { desc = "Cycle yank history forward" })
map("n", "]y", "<Plug>(YankyCycleBackward)", { desc = "Cycle yank history backward" })
map("n", "]p", "<Plug>(YankyPutIndentAfterLinewise)", { desc = "Put after, indented" })
map("n", "[p", "<Plug>(YankyPutIndentBeforeLinewise)", { desc = "Put before, indented" })
-- Delete and change go to the black-hole register: what you yanked stays
-- the thing you paste. Register-explicit deletes ("ad) still work.
map({ "n", "v" }, "d", [["_d]], { desc = "Delete (black hole)" })
map({ "n", "v" }, "D", [["_D]], { desc = "Delete to EOL (black hole)" })
map({ "n", "v" }, "c", [["_c]], { desc = "Change (black hole)" })
map({ "n", "v" }, "C", [["_C]], { desc = "Change to EOL (black hole)" })
map({ "n", "v" }, "x", [["_x]], { desc = "Delete char (black hole)" })

-- multicursor -------------------------------------------------------------
local mc = require("multicursor-nvim")
mc.setup()
map({ "n", "v" }, "<C-d>", function() mc.matchAddCursor(1) end, { desc = "Add cursor on next match" })
map({ "n", "v" }, "<C-S-d>", function() mc.matchAddCursor(-1) end, { desc = "Add cursor on previous match" })
map({ "n", "v" }, "<C-S-l>", function() mc.matchAllAddCursors() end, { desc = "Add cursors on all matches" })
-- Esc: re-enable disabled cursors, else clear cursors, else clear hlsearch.
-- Replaces the plain Esc/noh mapping from keymaps.lua for normal mode.
map("n", "<Esc>", function()
  if not mc.cursorsEnabled() then
    mc.enableCursors()
  elseif mc.hasCursors() then
    mc.clearCursors()
  else
    vim.cmd("nohlsearch")
  end
end, { desc = "Clear cursors / hlsearch" })

-- mini.ai: more text objects --------------------------------------------
-- vif inside function, dac around class, cio inside block/loop/conditional,
-- vit tag, vid digits, vie word-with-case, viu function call argument list.
-- Treesitter ones need a parser for the buffer's language.
local ai = require("mini.ai")
ai.setup({
  n_lines = 500,
  custom_textobjects = {
    o = ai.gen_spec.treesitter({
      a = { "@block.outer", "@conditional.outer", "@loop.outer" },
      i = { "@block.inner", "@conditional.inner", "@loop.inner" },
    }),
    f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
    c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
    t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
    d = { "%f[%d]%d+" },
    e = {
      { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
      "^().*()$",
    },
    u = ai.gen_spec.function_call(),
    U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }),
  },
})

-- mini.pairs: auto-close brackets and quotes -------------------------------
require("mini.pairs").setup({
  modes = { insert = true, command = true, terminal = false },
  skip_next = [=[[%w%%%'%[%"%.%`%$]]=], -- no pair when the next char is one of these
  skip_ts = { "string" },               -- no pair inside strings
  skip_unbalanced = true,               -- no pair when it would unbalance
  markdown = true,                      -- ``` fences
})

-- nvim-ts-autotag: close and rename HTML/JSX tags -----------------------
require("nvim-ts-autotag").setup({})

-- trouble: persistent lists for diagnostics, references, symbols -----------
require("trouble").setup({
  modes = {
    lsp = { win = { position = "right" } },
  },
})
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
map("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer diagnostics (Trouble)" })
map("n", "<leader>cs", "<cmd>Trouble symbols toggle<cr>", { desc = "Symbols (Trouble)" })
map("n", "<leader>cS", "<cmd>Trouble lsp toggle<cr>", { desc = "LSP references/definitions (Trouble)" })
map("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location list (Trouble)" })
map("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix list (Trouble)" })

-- inc-rename: live-preview symbol rename -----------------------------------
-- The <leader>cr mapping is set per buffer on LspAttach in plugins/lsp.lua
-- and uses :IncRename when this module has loaded.
require("inc_rename").setup({})
