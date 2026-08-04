local state = { active = false, pre_bufs = {}, from_history = false }

-- A modified buffer with one of these makes `:tabclose` fail with E445, since
-- it cannot be hidden even though 'hidden' is set.
local BLOCKING_BUFHIDDEN = { wipe = true, delete = true, unload = true }

-- Make blocking buffers hideable so the tab can close. `modified` is left
-- alone, so nothing unsaved is discarded.
local function unblock_tabclose(tabpage)
  local fixed = {}
  if not (tabpage and vim.api.nvim_tabpage_is_valid(tabpage)) then return fixed end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local bufhidden = vim.bo[buf].bufhidden
    if vim.bo[buf].modified and BLOCKING_BUFHIDDEN[bufhidden] then
      vim.bo[buf].bufhidden = "hide"
      table.insert(fixed, ("buf %d bufhidden=%s -> hide (%s)"):format(
        buf, bufhidden, vim.api.nvim_buf_get_name(buf)))
    end
  end
  return fixed
end

local function describe_tab(tabpage)
  if not (tabpage and vim.api.nvim_tabpage_is_valid(tabpage)) then
    return { "  <invalid tabpage: " .. tostring(tabpage) .. ">" }
  end
  local curwin = vim.api.nvim_get_current_win()
  local lines = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local buftype = vim.bo[buf].buftype
    -- nvim's `bufIsChanged` (what E445 tests) ignores `modified` for these.
    local dontwrite = buftype == "nofile" or buftype == "nowrite"
      or buftype == "terminal" or buftype == "prompt"
    table.insert(lines, ("  win %d%s buf %d mod=%s counts_as_changed=%s bufhidden=%q buftype=%q ft=%q float=%s pre_buf=%s nwins=%d name=%s"):format(
      win, win == curwin and " (cur)" or "", buf, tostring(vim.bo[buf].modified),
      tostring(vim.bo[buf].modified and not dontwrite), vim.bo[buf].bufhidden, buftype,
      vim.bo[buf].filetype, tostring(vim.api.nvim_win_get_config(win).relative ~= ""),
      tostring(state.pre_bufs[buf] == true), #vim.fn.win_findbuf(buf),
      vim.api.nvim_buf_get_name(buf)))
  end
  return lines
end

-- Close the view. If the close fails (E445 and friends), log which buffer
-- blocked it, unblock it, and retry once.
local function close_view()
  local back = state.from_history
  state.from_history = false

  local view = require("diffview.lib").get_current_view()
  local tabpage = view and view.tabpage
  local ok, err = pcall(vim.cmd, "DiffviewClose")

  if not ok then
    local report = { "DiffviewClose failed: " .. tostring(err) }
    table.insert(report, ("hidden=%s"):format(tostring(vim.o.hidden)))
    table.insert(report, "view tabpage windows AT view_leave (just before :tabclose):")
    vim.list_extend(report, state.leave_snapshot or { "  <no snapshot>" })
    table.insert(report, "view tabpage windows AFTER the failure:")
    vim.list_extend(report, describe_tab(tabpage))
    table.insert(report, "current tabpage windows:")
    vim.list_extend(report, describe_tab(vim.api.nvim_get_current_tabpage()))

    local fixed = unblock_tabclose(tabpage)
    vim.list_extend(fixed, unblock_tabclose(vim.api.nvim_get_current_tabpage()))
    table.insert(report, "unblocked: " .. (next(fixed) and table.concat(fixed, ", ") or "nothing"))

    local ok2, err2 = pcall(vim.cmd, "DiffviewClose")
    table.insert(report, "retry ok=" .. tostring(ok2) .. (ok2 and "" or (" err=" .. tostring(err2))))

    local logfile = vim.fs.joinpath(vim.fn.stdpath("state"), "diffview-close-failure.log")
    pcall(vim.fn.writefile, vim.split(table.concat(report, "\n"), "\n"), logfile)
    vim.notify(table.concat(report, "\n") .. "\nlogged to " .. logfile, vim.log.levels.WARN)
  end

  if back then
    vim.schedule(function() vim.cmd("DiffviewFileHistory") end)
  end
end

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
      view_leave = function(view)
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(buf) and not state.pre_bufs[buf] then
            if vim.bo[buf].modified then
              vim.bo[buf].modified = false
            end
          end
        end
        -- This runs immediately before diffview's :tabclose, so it is the only
        -- place that sees the state the close actually fails on.
        local tabpage = view and view.tabpage
        state.leave_snapshot = describe_tab(tabpage)

        -- Pre-existing buffers keep their `modified` flag (it may be real
        -- unsaved work), but a modified buffer that can't be hidden makes the
        -- upcoming :tabclose fail with E445. Making it hideable lets the tab
        -- close while the changes stay in the buffer.
        unblock_tabclose(tabpage)
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
        {
          "n",
          "q",
          close_view,
          { desc = "Close Diffview" },
        },
        { "n", "gf", goto_file_in_tab, { desc = "Open file in new tab" } },
        { "n", "<leader>e", "<cmd>DiffviewToggleFiles<cr>", { desc = "Toggle file panel" } },
      },
      file_panel = {
        {
          "n",
          "q",
          close_view,
          { desc = "Close Diffview" },
        },
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
        { "n", "<leader>e", "<cmd>DiffviewToggleFiles<cr>", { desc = "Toggle file panel" } },
      },
      file_history_panel = {
        { "n", "q", close_view, { desc = "Close Diffview" } },
        { "n", "gf", goto_file_in_tab, { desc = "Open file in new tab" } },
        { "n", "<leader>e", "<cmd>DiffviewToggleFiles<cr>", { desc = "Toggle file panel" } },
        {
          "n",
          "gd",
          function()
            local lib = require("diffview.lib")
            local view = lib.get_current_view()
            if not view or not view.panel then return end
            local item = view.panel:get_item_at_cursor()
            if not item then return end
            local commit = item.commit or (item.parent and item.parent.commit)
            if not commit then return end
            local hash = commit.hash
            state.from_history = true
            vim.cmd("DiffviewClose")
            vim.schedule(function()
              vim.cmd("DiffviewOpen " .. hash .. "^.." .. hash)
            end)
          end,
          { desc = "Open commit in Diffview" },
        },
      },
    },
  },
  config = function(_, opts)
    require("diffview").setup(opts)

    local Layout = require("diffview.scene.layout").Layout
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

    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = function()
        if state.active then
          vim.cmd("DiffviewClose")
        end
      end,
    })

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
