local state = { active = false, pre_bufs = {} }

local function goto_file_in_tab()
  require("diffview.actions").goto_file_tab()
  local tab = vim.api.nvim_get_current_tabpage()
  local group = vim.api.nvim_create_augroup("DiffviewGfTab" .. tab, { clear = true })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function()
      if vim.api.nvim_get_current_tabpage() ~= tab then return end
      vim.keymap.set("n", "q", "<cmd>tabclose<cr>", { buffer = true, desc = "Close tab" })
    end,
  })
  vim.api.nvim_create_autocmd("TabClosed", {
    group = group,
    callback = function()
      pcall(vim.api.nvim_del_augroup_by_id, group)
    end,
  })
  vim.keymap.set("n", "q", "<cmd>tabclose<cr>", { buffer = true, desc = "Close tab" })
end

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
        { "n", "gf", goto_file_in_tab, { desc = "Open file in new tab" } },
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

            local paths = {}
            if is_dir then
              local node = item._node
              if node then
                node:deep_some(function(n)
                  if n.data and n.data.path and not n:has_children() then
                    table.insert(paths, { path = n.data.path, kind = n.data.kind })
                  end
                end)
              end
            else
              table.insert(paths, { path = item.path, kind = item.kind })
            end

            local async = require("diffview.async")
            async.void(function()
              for _, p in ipairs(paths) do
                require("diffview.async").await(view.adapter:file_restore(p.path, p.kind, nil))
              end
              view:update_files()
            end)()
          end,
          { desc = "Discard file/directory changes" },
        },
        { "n", "gf", goto_file_in_tab, { desc = "Open file in new tab" } },
      },
      file_history_panel = {
        { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
        { "n", "gf", goto_file_in_tab, { desc = "Open file in new tab" } },
      },
    },
  },
  config = function(_, opts)
    require("diffview").setup(opts)

    local Layout = require("diffview.scene.layout")
    local async = require("diffview.async")
    local await = async.await

    Layout.open_files = async.void(function(self)
      if not self:is_valid() then return end

      if #self:files() < #self.windows then
        self:open_null()
        self.emitter:emit("files_opened")
        return
      end

      vim.cmd("diffoff!")

      if not self:is_files_loaded() then
        self:open_null()
        for _, win in ipairs(self.windows) do
          if not self:is_valid() then return end
          await(win:load_file())
        end
      end

      if not self:is_valid() then return end
      await(async.scheduler())

      if not self:is_valid() then return end
      for _, win in ipairs(self.windows) do
        if not self:is_valid() then return end
        await(win:open_file())
      end

      if not self:is_valid() then return end
      self:sync_scroll()
      self.emitter:emit("files_opened")
    end)

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
