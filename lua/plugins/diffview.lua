-- Diffview runs more than one view at a time: a file-history tab alongside a
-- diff tab, and the close-then-reopen dance behind `gd`. So there is no such
-- thing as "the" view, and describing one in module-level variables is what
-- caused the cleanup to silently no-op when views overlapped, buffers to be
-- deleted against another view's snapshot, and a return-to-history flag to
-- survive and fire on an unrelated view.
--
-- Instead: one session per view, keyed by the view itself, which every hook
-- receives (diffview/config.lua:622 forwards the emitted args). Weak keys so a
-- view that somehow never emits view_closed is collected with its session
-- rather than pinning both for the life of the editor.
local sessions = setmetatable({}, { __mode = "k" })

-- `gd` closes the current view before its replacement exists, so the intent to
-- return to the file history afterwards cannot be stored on either view. It is
-- a one-shot token, claimed by whichever view opens next and cleared as it is
-- claimed.
local pending_return_to_history = false

-- Which views a buffer might belong to: buf -> set of views that were open when
-- it was created.
--
-- Ownership used to be inferred by diffing the buffer list at view_opened
-- against the list at view_closed. That cannot describe overlapping views: a
-- buffer opened during view A also predates view B, so B protected it forever
-- and nothing ever collected it, while A's snapshot could equally delete
-- buffers B had been started with. Recording ownership when the buffer appears,
-- and collecting it once every view that could have caused it is gone, is
-- reference counting instead of guesswork and composes with any number of views.
local owners = {}

local function attribute_buffer(buf)
  if next(sessions) == nil then return end
  local set = {}
  for view in pairs(sessions) do
    set[view] = true
  end
  owners[buf] = set
end

-- Release `view`'s claim on every buffer it owned, returning those left with no
-- owner at all.
local function release_claims(view)
  local orphaned = {}
  for buf, set in pairs(owners) do
    if not vim.api.nvim_buf_is_valid(buf) then
      owners[buf] = nil
    elseif set[view] then
      set[view] = nil
      if next(set) == nil then
        owners[buf] = nil
        table.insert(orphaned, buf)
      end
    end
  end
  return orphaned
end

-- What actually makes diffview's `:tabclose` fail, established by brute-forcing
-- bufhidden x buftype x modified x float x shared-buffer on nvim 0.12:
--
--   a window in the closing tab holds a buffer that is `modified`, has a
--   `bufhidden` that forbids hiding, and has a `buftype` that counts as
--   writable.
--
-- E445 ("other window contains changes") when that window is not the current
-- one, E37 when it is. Buffers displayed in no window, and buffers in other
-- tabs, never block. `acwrite` and `help` do count as writable, so they are not
-- in the exempt list below.
local NON_HIDEABLE = { wipe = true, delete = true, unload = true }
local DONTWRITE = { nofile = true, nowrite = true, terminal = true, prompt = true }

local function is_blocker(buf)
  return vim.bo[buf].modified
    and NON_HIDEABLE[vim.bo[buf].bufhidden]
    and not DONTWRITE[vim.bo[buf].buftype]
end

-- Every buffer matching the predicate, and where it is displayed. Scans all
-- buffers rather than the windows of one tabpage: the previous version could
-- only ever report what was already visible in the view, which is why it kept
-- logging a clean tab alongside a real E445.
local function find_blockers()
  local lines = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and is_blocker(buf) then
      local wins, tabs = vim.fn.win_findbuf(buf), {}
      for _, win in ipairs(wins) do
        table.insert(tabs, vim.api.nvim_win_get_tabpage(win))
      end
      table.insert(lines, ("  buf %d bufhidden=%q buftype=%q wins=[%s] tabs=[%s] name=%s"):format(
        buf, vim.bo[buf].bufhidden, vim.bo[buf].buftype,
        table.concat(vim.tbl_map(tostring, wins), " "),
        table.concat(vim.tbl_map(tostring, tabs), " "),
        vim.api.nvim_buf_get_name(buf)))
    end
  end
  return lines
end

-- Make blocking buffers hideable so the tab can close. Only a buffer shown in
-- some window can block, so nothing else is touched, and `modified` is left
-- alone -- the unsaved changes simply stay in the buffer.
--
-- Returns the previous `bufhidden` per buffer, because these buffers belong to
-- other plugins (Oil sets `wipe` on the files it previews) and silently leaving
-- them hideable changed their lifetime for the rest of the session.
local function unblock_tabclose()
  local original = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and is_blocker(buf) and #vim.fn.win_findbuf(buf) > 0 then
      original[buf] = vim.bo[buf].bufhidden
      vim.bo[buf].bufhidden = "hide"
    end
  end
  return original
end

local function describe_unblocked(original)
  local lines = {}
  for buf, was in pairs(original) do
    table.insert(lines, ("buf %d bufhidden=%s -> hide (%s)"):format(
      buf, was, vim.api.nvim_buf_get_name(buf)))
  end
  return lines
end

-- Tear down the tabs `gf` opened for this view. Their buffers are then held by
-- no window, so the sweep can collect them without ever deleting a buffer out
-- from under something visible. A tab showing unsaved work is left alone -- you
-- asked for that file, and losing sight of it is worse than an extra tab.
local function close_session_tabs(session)
  for _, tab in ipairs(session.tabs) do
    if vim.api.nvim_tabpage_is_valid(tab) then
      local dirty = false
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
        if vim.bo[vim.api.nvim_win_get_buf(win)].modified then
          dirty = true
          break
        end
      end
      if not dirty then
        -- Fails harmlessly on the last remaining tabpage.
        pcall(vim.cmd, ("tabclose %d"):format(vim.api.nvim_tabpage_get_number(tab)))
      end
    end
  end
end

-- Hand `bufhidden` back to whoever owned it. Only revert a buffer still sitting
-- at exactly the value we wrote, so a deliberate change by its owner in the
-- meantime is not stomped.
local function restore_bufhidden(original)
  for buf, was in pairs(original or {}) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].bufhidden == "hide" then
      vim.bo[buf].bufhidden = was
    end
  end
end

-- Close the view. If the close fails, record which buffers matched the
-- predicate, unblock them, and retry once.
local function close_view()
  -- Read the token off this view's session now: the session is gone by the time
  -- the close returns.
  local view = require("diffview.lib").get_current_view()
  local session = view and sessions[view]
  local back = session ~= nil and session.return_to_history or false

  local ok, err = pcall(vim.cmd, "DiffviewClose")

  if not ok then
    local report = {
      "DiffviewClose failed: " .. tostring(err),
      ("hidden=%s"):format(tostring(vim.o.hidden)),
      "blockers recorded at view_leave:",
    }
    vim.list_extend(report, session and session.leave_blockers or { "  <nothing recorded>" })
    table.insert(report, "blockers after the failure:")
    local now = find_blockers()
    vim.list_extend(report, next(now) and now or { "  <none>" })

    local fixed = describe_unblocked(unblock_tabclose())
    table.insert(report, "unblocked: " .. (next(fixed) and table.concat(fixed, ", ") or "nothing"))

    local ok2, err2 = pcall(vim.cmd, "DiffviewClose")
    table.insert(report, "retry ok=" .. tostring(ok2) .. (ok2 and "" or (" err=" .. tostring(err2))))

    local logfile = vim.fs.joinpath(vim.fn.stdpath("state"), "diffview-close-failure.log")
    pcall(vim.fn.writefile, vim.split(table.concat(report, "\n"), "\n"), logfile)

    -- The retry has always succeeded so far, and a wall of text about a
    -- recovered failure is worse than the failure was. Stay quiet unless the
    -- view is genuinely still open; the log is there either way.
    if not ok2 then
      vim.notify(table.concat(report, "\n") .. "\nlogged to " .. logfile, vim.log.levels.ERROR)
    end
  end

  if back then
    vim.schedule(function() vim.cmd("DiffviewFileHistory") end)
  end
end

local function goto_file_in_tab()
  -- Capture the view before jumping: afterwards the cursor is in the new tab and
  -- get_current_view() no longer reports the view we came from.
  local view = require("diffview.lib").get_current_view()
  local session = view and sessions[view]

  local before = {}
  for _, t in ipairs(vim.api.nvim_list_tabpages()) do
    before[t] = true
  end

  require("diffview.actions").goto_file_tab()
  local tab = vim.api.nvim_get_current_tabpage()

  -- Only remember a tab we actually caused. goto_file_tab reuses an existing tab
  -- when the file is already open in one, and closing that on teardown would
  -- take a tab the user had before diffview ever ran.
  if session and not before[tab] then
    table.insert(session.tabs, tab)
  end

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
  event = "VeryLazy",
  cmd = { "DiffviewOpen", "DiffviewFileHistory" },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview Open" },
    { "<leader>gf", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview File History" },
    { "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview Git Log" },
  },
  opts = {
    -- Files above this size are diffed as binary, so `git log --numstat` does
    -- not line-diff them. The whole-repo file history spent ~50s line-diffing
    -- multi-hundred-MB JSON dumps in one repo; with this it takes ~8s. Such
    -- files still open and diff in the view (that goes through `git show` and
    -- vim's diff mode), they only lose the +N -N counts in the panel.
    git_cmd = { "git", "-c", "core.bigFileThreshold=5m" },
    file_history_panel = {
      log_options = {
        git = {
          -- Diffview stops at 256 commits by default and the panel simply ends
          -- there. Load the whole log; entries stream in, so the panel is
          -- usable while the rest loads.
          single_file = { max_count = false },
          multi_file = { max_count = false },
        },
      },
    },
    watch_index = true,
    hooks = {
      -- snacks bigfile only guards real files, so the git-side diffview://
      -- scratch buffers get full treesitter/diagnostics no matter the size.
      -- Apply the same 500KB cutoff to every diff buffer.
      diff_buf_read = function(bufnr)
        local lines = vim.api.nvim_buf_line_count(bufnr)
        if vim.api.nvim_buf_get_offset(bufnr, lines) > 500 * 1024 then
          vim.b[bufnr].diffview_bigfile = true
          vim.treesitter.stop(bufnr)
          vim.bo[bufnr].syntax = ""
          vim.b[bufnr].minidiff_disable = true
          vim.diagnostic.enable(false, { bufnr = bufnr })
        end
      end,
      diff_buf_win_enter = function(bufnr, winid)
        if vim.b[bufnr].diffview_bigfile then
          vim.wo[winid].foldenable = false
          vim.wo[winid].foldmethod = "manual"
        end
      end,
      view_opened = function(view)
        if not view or sessions[view] then return end
        sessions[view] = {
          return_to_history = pending_return_to_history,
          unblocked = {},
          tabs = {},
        }
        pending_return_to_history = false
      end,
      view_leave = function(view)
        local session = view and sessions[view]
        if not session then return end

        -- diffview maps `tab_leave` onto `view_leave` (diffview/init.lua:263),
        -- so this fires every time the tab merely loses focus. View:close()
        -- sends `closing` before emitting, so it is what separates a real
        -- teardown from a tab switch. Without this gate the work below ran on
        -- every tab switch.
        if not (view.closing and view.closing:check()) then return end

        -- Runs immediately before diffview's :tabclose, so it sees the state the
        -- close actually fails on.
        session.leave_blockers = find_blockers()

        -- A modified buffer that cannot be hidden makes the upcoming :tabclose
        -- fail. Making it hideable lets the tab close with the changes intact.
        session.unblocked = unblock_tabclose()
      end,
      view_closed = function(view)
        local session = view and sessions[view]
        if not session then return end
        sessions[view] = nil

        restore_bufhidden(session.unblocked)

        -- Claims are released now, while `view` is still a valid key, but the
        -- deletions are deferred: diffview is still unwinding its own close.
        local orphaned = release_claims(view)

        vim.schedule(function()
          -- Before the sweep, so the files `gf` opened stop being displayed and
          -- become ordinary collection candidates.
          close_session_tabs(session)

          local kept = {}
          for _, buf in ipairs(orphaned) do
            local name = vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_name(buf) or ""
            if name ~= "" then
              if vim.bo[buf].modified then
                -- Never force-delete unsaved work. This used to clear `modified`
                -- in view_leave and then wipe the buffer here, so edits to a
                -- file opened during the session -- via gf, say -- were
                -- discarded without a prompt.
                table.insert(kept, vim.fn.fnamemodify(name, ":~:."))
              elseif #vim.fn.win_findbuf(buf) == 0 then
                -- Still displayed after close_session_tabs means a window we did
                -- not open is showing it, and deleting it would yank the buffer
                -- out from under that window.
                pcall(vim.api.nvim_buf_delete, buf, { force = true })
              end
            end
          end

          if next(kept) then
            vim.notify("Kept unsaved buffer(s): " .. table.concat(kept, ", "), vim.log.levels.INFO)
          end
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
            -- Hand the "q returns to the log" intent to the view opened below.
            -- It cannot live on a view: this one is about to be destroyed and
            -- its replacement does not exist yet.
            pending_return_to_history = true
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

    -- Attribution has to happen as buffers appear, so it lives here rather than
    -- in a hook. Registered on plugin load, which is before any view can open.
    vim.api.nvim_create_autocmd("BufNew", {
      callback = function(args) attribute_buffer(args.buf) end,
    })
    vim.api.nvim_create_autocmd("BufWipeout", {
      callback = function(args) owners[args.buf] = nil end,
    })

    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = function()
        if next(sessions) == nil then return end
        -- Close every open view, not just the current one. `DiffviewClose` only
        -- ever touches the focused view, so a second view survived into exit.
        -- Iterate a copy: closing mutates lib.views.
        local lib = require("diffview.lib")
        for _, view in ipairs({ unpack(lib.views) }) do
          pcall(function()
            view:close()
            lib.dispose_view(view)
          end)
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
