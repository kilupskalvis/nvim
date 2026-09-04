-- UI: statusline, buffer bar, message/cmdline UI, decorations. Each block
-- is independent; delete one to remove the feature.
local map = vim.keymap.set
local icons = {
  diagnostics = { Error = " ", Warn = " ", Hint = " ", Info = " " },
  git = { added = " ", modified = " ", removed = " " },
}

-- lualine: statusline -----------------------------------------------------
-- One global line (laststatus=3 in options). LazyVim's layout minus the clock.
require("lualine").setup({
  options = {
    theme = "auto",
    globalstatus = true,
    disabled_filetypes = { statusline = { "snacks_dashboard" } },
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch" },
    lualine_c = {
      { "diagnostics", symbols = icons.diagnostics },
      { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
      { "filename", path = 1 }, -- relative path
    },
    lualine_x = {
      -- what noice is showing: recording macro, pending operator
      {
        function() return require("noice").api.status.command.get() end,
        cond = function() return package.loaded["noice"] and require("noice").api.status.command.has() end,
        color = function() return { fg = Snacks.util.color("Statement") } end,
      },
      {
        function() return require("noice").api.status.mode.get() end,
        cond = function() return package.loaded["noice"] and require("noice").api.status.mode.has() end,
        color = function() return { fg = Snacks.util.color("Constant") } end,
      },
      -- git line counts, from gitsigns so both agree
      {
        "diff",
        symbols = icons.git,
        source = function()
          local gs = vim.b.gitsigns_status_dict
          if gs then return { added = gs.added, modified = gs.changed, removed = gs.removed } end
        end,
      },
    },
    lualine_y = {
      { "progress", separator = " ", padding = { left = 1, right = 0 } },
      { "location", padding = { left = 0, right = 1 } },
    },
    lualine_z = {},
  },
  extensions = { "quickfix", "oil", "trouble" },
})

-- bufferline: buffers as tabs along the top --------------------------------
require("bufferline").setup({
  options = {
    -- x on a tab or right-click deletes without losing the window layout
    close_command = function(n) require("snacks").bufdelete(n) end,
    right_mouse_command = function(n) require("snacks").bufdelete(n) end,
    diagnostics = "nvim_lsp",
    always_show_bufferline = false, -- hidden with a single buffer
    diagnostics_indicator = function(_, _, diag)
      local ret = (diag.error and icons.diagnostics.Error .. diag.error .. " " or "")
        .. (diag.warning and icons.diagnostics.Warn .. diag.warning or "")
      return vim.trim(ret)
    end,
    offsets = { { filetype = "snacks_layout_box" } },
  },
})
-- Redraw after buffer list changes so closed buffers disappear at once.
vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
  group = vim.api.nvim_create_augroup("config_bufferline", { clear = true }),
  callback = function() vim.schedule(function() pcall(nvim_bufferline) end) end,
})
map("n", "<leader>bp", "<cmd>BufferLineTogglePin<cr>", { desc = "Pin buffer" })
map("n", "<leader>bP", "<cmd>BufferLineGroupClose ungrouped<cr>", { desc = "Delete non-pinned buffers" })
map("n", "<leader>br", "<cmd>BufferLineCloseRight<cr>", { desc = "Delete buffers to the right" })
map("n", "<leader>bl", "<cmd>BufferLineCloseLeft<cr>", { desc = "Delete buffers to the left" })
map("n", "<leader>bj", "<cmd>BufferLinePick<cr>", { desc = "Pick buffer" })
map("n", "[B", "<cmd>BufferLineMovePrev<cr>", { desc = "Move buffer left" })
map("n", "]B", "<cmd>BufferLineMoveNext<cr>", { desc = "Move buffer right" })
-- [b ]b <leader>h <leader>l keep their :bprevious/:bnext from keymaps.lua;
-- bufferline shows the same order, so cycling matches what you see.

-- noice: cmdline, messages and LSP progress as floating UI ---------------
require("noice").setup({
  lsp = {
    -- let noice render hover/signature markdown (better than the default)
    override = {
      ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true,
    },
  },
  routes = {
    -- "written", "N more lines", "N fewer lines" go to the quiet mini view
    {
      filter = {
        event = "msg_show",
        any = { { find = "%d+L, %d+B" }, { find = "; after #%d+" }, { find = "; before #%d+" } },
      },
      view = "mini",
    },
  },
  presets = {
    bottom_search = true,         -- / and ? stay at the bottom like classic vim
    command_palette = true,       -- : cmdline centered with completion popup below
    long_message_to_split = true, -- long output opens in a split instead of hit-enter
  },
})
map("c", "<S-Enter>", function() require("noice").redirect(vim.fn.getcmdline()) end, { desc = "Redirect cmdline output to a split" })
map("n", "<leader>snl", function() require("noice").cmd("last") end, { desc = "Last message" })
map("n", "<leader>snh", function() require("noice").cmd("history") end, { desc = "Message history" })
map("n", "<leader>sna", function() require("noice").cmd("all") end, { desc = "All messages" })
map("n", "<leader>snd", function() require("noice").cmd("dismiss") end, { desc = "Dismiss all" })
map({ "i", "n", "s" }, "<C-f>", function()
  if not require("noice.lsp").scroll(4) then return "<C-f>" end
end, { silent = true, expr = true, desc = "Scroll forward (hover doc or page)" })
map({ "i", "n", "s" }, "<C-b>", function()
  if not require("noice.lsp").scroll(-4) then return "<C-b>" end
end, { silent = true, expr = true, desc = "Scroll backward (hover doc or page)" })

-- todo-comments: highlight TODO/FIXME/HACK/NOTE and jump between them ----
require("todo-comments").setup({})
map("n", "]t", function() require("todo-comments").jump_next() end, { desc = "Next todo comment" })
map("n", "[t", function() require("todo-comments").jump_prev() end, { desc = "Previous todo comment" })
map("n", "<leader>xt", "<cmd>Trouble todo toggle<cr>", { desc = "Todo (Trouble)" })
map("n", "<leader>st", function() Snacks.picker.todo_comments() end, { desc = "Todo" })
map("n", "<leader>sT", function() Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } }) end, { desc = "Todo/Fix/Fixme" })

-- mini.hipatterns: color swatches for #hex and tailwind class names -------
local hi = require("mini.hipatterns")
hi.setup({
  tailwind = {
    enabled = true,
    ft = { "css", "html", "htmldjango", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte", "astro" },
    style = "full",
  },
  highlighters = {
    hex_color = hi.gen_highlighter.hex_color({ priority = 2000 }),
    -- #abc shorthand
    shorthand = {
      pattern = "()#%x%x%x()%f[^%x%w]",
      group = function(_, _, data)
        local m = data.full_match
        if m == "#add" then return end
        local r, g, b = m:sub(2, 2), m:sub(3, 3), m:sub(4, 4)
        return MiniHipatterns.compute_hex_color_group("#" .. r .. r .. g .. g .. b .. b, "bg")
      end,
      extmark_opts = { priority = 2000 },
    },
  },
})

-- smear-cursor: animated cursor trail -------------------------------------
require("smear_cursor").setup({
  smear_between_buffers = true,
  smear_between_neighbor_lines = true,
  smear_to_cmd = true,
  -- Screen space: in buffer space every wheel tick drew a trail across the
  -- viewport and kept animating through the scroll.
  scroll_buffer_space = false,
  -- hide_target_hack without never_draw_over_target made the cell under the
  -- cursor flicker; the plugin's own docs warn against the combination.
  hide_target_hack = false,
  -- Fast head, lagging tail: snappy cursor, long trail.
  stiffness = 0.8,
  trailing_stiffness = 0.35,
  damping = 0.9,
  distance_stop_animating = 0.3,
  time_interval = 7,
})
