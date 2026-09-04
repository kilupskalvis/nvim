-- oil: the file explorer is a buffer. Edit names to rename, delete lines to
-- delete, :w applies. <leader>e toggles a float; h/l go up and into.
require("oil").setup({
  default_file_explorer = true, -- opening a directory opens oil instead of netrw
  delete_to_trash = true,
  float = { padding = 2, max_width = 0.8, max_height = 0.8 },
  keymaps = {
    ["q"] = { callback = function() require("oil").close() end, desc = "Close oil" },
    -- hjkl navigation. Costs normal-mode h/l cursor movement inside names
    -- (use w/b/0/$ when renaming).
    ["h"] = "actions.parent",
    ["l"] = "actions.select",
  },
  view_options = { show_hidden = true },
})

-- Start screen: bare `nvim` shows the directory you launched in, as a plain
-- oil window. `nvim .` and `:e somedir` land in the same place, so there is
-- one behavior for "I opened nvim without a file". <leader>e keeps the float
-- for browsing while editing.
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("config_oil_start", { clear = true }),
  nested = true,
  callback = function()
    -- only with no file arguments, nothing piped in, and an untouched buffer
    if vim.fn.argc() > 0 or vim.bo.buftype ~= "" or vim.api.nvim_buf_get_name(0) ~= "" then return end
    if vim.api.nvim_buf_line_count(0) > 1 or vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] ~= "" then return end
    -- A deleted cwd (shell left in a removed directory) makes uv.cwd() nil and
    -- every path lookup assert; oil would then show "Loading" forever.
    local cwd = vim.uv.cwd()
    if not cwd then
      cwd = vim.env.HOME
      vim.cmd.cd(cwd)
      vim.notify("Working directory no longer exists, using " .. cwd, vim.log.levels.WARN)
    end
    require("oil").open(cwd)
  end,
})

-- toggle_float, not open_float: pressing <leader>e inside the float would
-- nest a second float whose origin window is the first, so the next selected
-- file opened inside the oil float instead of a normal window.
vim.keymap.set("n", "<leader>e", function() require("oil").toggle_float() end, { desc = "File explorer (oil)" })
