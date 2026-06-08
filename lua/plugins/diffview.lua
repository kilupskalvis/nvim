local pre_bufs = {}

return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory" },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview Open" },
    { "<leader>gf", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview File History" },
  },
  opts = {
    watch_index = true,
    hooks = {
      view_opened = function()
        pre_bufs = {}
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
            pre_bufs[buf] = true
          end
        end
      end,
      view_leave = function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(buf) and not pre_bufs[buf] then
            if vim.bo[buf].modified then
              vim.bo[buf].modified = false
            end
          end
        end
      end,
      view_closed = function()
        vim.defer_fn(function()
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_valid(buf) and not pre_bufs[buf] then
              local name = vim.api.nvim_buf_get_name(buf)
              if name ~= "" then
                vim.api.nvim_buf_delete(buf, { force = true })
              end
            end
          end
          pre_bufs = {}
        end, 100)
      end,
    },
    keymaps = {
      view = {
        { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
        {
          "n",
          "gf",
          function()
            require("diffview.actions").goto_file_tab()
            vim.keymap.set("n", "q", "<cmd>tabclose<cr>", { buffer = true, desc = "Back to Diffview" })
          end,
          { desc = "Open file in new tab" },
        },
      },
      file_panel = {
        { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
        {
          "n",
          "gf",
          function()
            require("diffview.actions").goto_file_tab()
            vim.keymap.set("n", "q", "<cmd>tabclose<cr>", { buffer = true, desc = "Back to Diffview" })
          end,
          { desc = "Open file in new tab" },
        },
      },
      file_history_panel = {
        { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
        {
          "n",
          "gf",
          function()
            require("diffview.actions").goto_file_tab()
            vim.keymap.set("n", "q", "<cmd>tabclose<cr>", { buffer = true, desc = "Back to Diffview" })
          end,
          { desc = "Open file in new tab" },
        },
      },
    },
  },
  config = function(_, opts)
    require("diffview").setup(opts)
    vim.api.nvim_create_autocmd("BufWritePost", {
      callback = function()
        local lib = require("diffview.lib")
        local view = lib.get_current_view()
        if view then
          view:update_files()
        end
      end,
    })
  end,
}
