return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = false,
  opts = {
    default_file_explorer = true,
    delete_to_trash = true,
    float = {
      padding = 2,
      max_width = 0.8,
      max_height = 0.8,
    },
    keymaps = {
      ["q"] = { callback = function() require("oil").close() end, desc = "Close oil" },
    },
    view_options = {
      show_hidden = true,
    },
  },
  config = function(_, opts)
    require("oil").setup(opts)
    -- When nvim opens a directory, oil loads as a regular buffer.
    -- Redirect it into a float to keep a consistent UX.
    vim.api.nvim_create_autocmd("BufWinEnter", {
      pattern = "oil://*",
      callback = function(args)
        local win = vim.api.nvim_get_current_win()
        if vim.api.nvim_win_get_config(win).relative == "" then
          -- Capture the dir before bdelete; afterwards the current buffer is
          -- unnamed and open_float() would fall back to the cwd.
          local dir = require("oil").get_current_dir(args.buf)
          vim.schedule(function()
            vim.cmd.bdelete()
            -- bdelete leaves a [No Name] buffer in the window; keep it out of
            -- the buffer list and wipe it once a real file replaces it
            vim.bo.buflisted = false
            vim.bo.bufhidden = "wipe"
            require("oil").open_float(dir)
          end)
        end
      end,
    })
  end,
  keys = {
    -- toggle_float, not open_float: pressing <leader>e inside the float would
    -- nest a second float whose "origin window" is the first one, so the next
    -- selected file opened inside the oil float instead of a normal window
    { "<leader>e", function() require("oil").toggle_float() end, desc = "File Explorer (oil)" },
  },
}
