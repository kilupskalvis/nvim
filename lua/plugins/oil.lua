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

-- `nvim .` and `:e somedir` open oil as a regular buffer. Redirect into the
-- float so every way of landing in oil looks the same.
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = vim.api.nvim_create_augroup("config_oil_float", { clear = true }),
  pattern = "oil://*",
  callback = function(args)
    local win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_config(win).relative ~= "" then return end
    -- Capture the dir before bdelete; afterwards the current buffer is
    -- unnamed and open_float() would fall back to the cwd.
    local dir = require("oil").get_current_dir(args.buf)
    vim.schedule(function()
      vim.cmd.bdelete()
      -- bdelete leaves a [No Name] buffer; keep it unlisted and wipe it
      -- once a real file replaces it.
      vim.bo.buflisted = false
      vim.bo.bufhidden = "wipe"
      require("oil").open_float(dir)
    end)
  end,
})

-- toggle_float, not open_float: pressing <leader>e inside the float would
-- nest a second float whose origin window is the first, so the next selected
-- file opened inside the oil float instead of a normal window.
vim.keymap.set("n", "<leader>e", function() require("oil").toggle_float() end, { desc = "File explorer (oil)" })
