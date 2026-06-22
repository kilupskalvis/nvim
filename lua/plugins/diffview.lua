local state = { active = false, pre_bufs = {} }

return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory" },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview Open" },
    { "<leader>gf", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview File History" },
    { "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview Git Log" },
  },
  opts = {
    watch_index = true,
    hooks = {
      view_opened = function()
        if state.active then return end
        state.active = true
        state.pre_bufs = {}
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
            state.pre_bufs[buf] = true
          end
        end
      end,
      view_leave = function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(buf) and not state.pre_bufs[buf] then
            if vim.bo[buf].modified then
              vim.bo[buf].modified = false
            end
          end
        end
      end,
      view_closed = function()
        state.active = false
        vim.schedule(function()
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_valid(buf) and not state.pre_bufs[buf] then
              local name = vim.api.nvim_buf_get_name(buf)
              if name ~= "" then
                pcall(vim.api.nvim_buf_delete, buf, { force = true })
              end
            end
          end
          state.pre_bufs = {}
        end)
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
          "d",
          function()
            local lib = require("diffview.lib")
            local view = lib.get_current_view()
            if not view then return end

            local item = view:infer_cur_file(true)
            if not item then return end

            local is_dir = type(item.collapsed) == "boolean"
            local prompt = is_dir
              and ("Discard all changes in %s/?"):format(item.path)
              or ("Discard changes to %s?"):format(item.path)

            if vim.fn.confirm(prompt, "&Yes\n&No", 2) ~= 1 then return end

            local function discard_path(path, kind)
              local toplevel = view.adapter.ctx.toplevel
              if kind == "staged" then
                vim.fn.system({ "git", "-C", toplevel, "reset", "HEAD", "--", path })
              else
                vim.fn.system({ "git", "-C", toplevel, "checkout", "--", path })
              end
            end

            if is_dir then
              local node = item._node
              if node then
                node:deep_some(function(n)
                  if n.data and n.data.path and not n:has_children() then
                    discard_path(n.data.path, n.data.kind)
                  end
                end)
              end
            else
              discard_path(item.path, item.kind)
            end
            view:update_files()
          end,
          { desc = "Discard file/directory changes" },
        },
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
