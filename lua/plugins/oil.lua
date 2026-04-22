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
      ["<CR>"] = {
        callback = function()
          local oil = require("oil")
          local entry = oil.get_cursor_entry()
          if entry and entry.type == "file" then
            local dir = oil.get_current_dir()
            local filepath = vim.fn.fnamemodify(dir .. entry.name, ":p")
            local float_win = vim.api.nvim_get_current_win()
            -- Find the parent window behind the float
            local parent_win
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              if win ~= float_win and vim.api.nvim_win_get_config(win).relative == "" then
                parent_win = win
              end
            end
            -- Close the float
            vim.api.nvim_win_close(float_win, true)
            -- Open file in parent window
            if parent_win then
              vim.api.nvim_set_current_win(parent_win)
            end
            local buf = vim.fn.bufnr(filepath)
            if buf ~= -1 then
              vim.api.nvim_set_current_buf(buf)
            else
              vim.cmd.edit(filepath)
            end
          else
            oil.select()
          end
        end,
        desc = "Open file or enter directory",
      },
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
      callback = function()
        local win = vim.api.nvim_get_current_win()
        if vim.api.nvim_win_get_config(win).relative == "" then
          vim.schedule(function()
            vim.cmd.bdelete()
            require("oil").open_float()
          end)
        end
      end,
    })
  end,
  keys = {
    { "<leader>e", function() require("oil").open_float() end, desc = "File Explorer (oil)" },
  },
}
