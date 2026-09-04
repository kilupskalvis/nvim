-- vim.api.nvim_create_autocmd(events, { group, pattern, callback })
--   events:   one event name or a list. :help autocmd-events lists them all.
--   group:    an augroup id. `clear = true` on the group means re-sourcing
--             this file replaces the old autocmds instead of stacking them.
--   pattern:  what the event's <amatch> must match, usually a filetype or
--             file glob. Omit for "every time".
--   callback: Lua function; receives a table with buf, match, event, file.
local function augroup(name)
  return vim.api.nvim_create_augroup("config_" .. name, { clear = true })
end
local autocmd = vim.api.nvim_create_autocmd

-- Reload files changed outside nvim ------------------------------------
-- 'autoread' only checks on a few events. FocusGained/TermClose/TermLeave
-- cover switching back from elsewhere. CursorHold fires once after
-- 'updatetime' (200ms) of inactivity, so a file rewritten by an agent while
-- nvim already has focus is picked up too. checktime is a stat() per loaded
-- buffer; cheap. Scratch buffers (buftype=nofile) have no file to check.
autocmd({ "FocusGained", "TermClose", "TermLeave", "CursorHold", "CursorHoldI", "BufEnter" }, {
  group = augroup("checktime"),
  callback = function()
    -- The command-line window (q: / q/) forbids most commands: E11 on checktime.
    if vim.fn.getcmdwintype() ~= "" then return end
    if vim.o.buftype ~= "nofile" then vim.cmd("checktime") end
  end,
})

-- Say so when a buffer was reloaded from disk. Otherwise text changes under
-- the cursor with no explanation. A modified buffer is never silently
-- replaced: nvim raises W12 and asks.
autocmd("FileChangedShellPost", {
  group = augroup("checktime_notify"),
  callback = function(args)
    local name = vim.api.nvim_buf_get_name(args.buf)
    vim.notify(("Reloaded from disk: %s"):format(vim.fn.fnamemodify(name, ":~:.")), vim.log.levels.INFO)
  end,
})

-- Flash the yanked region ------------------------------------------------
autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function() vim.hl.on_yank() end,
})

-- Keep splits equal when the terminal is resized --------------------------
autocmd("VimResized", {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})

-- Reopen a file where you left it ----------------------------------------
-- The '"' mark is the cursor position when the buffer was last exited; it is
-- saved in shada across sessions. Once per buffer, and not for commit
-- messages, where starting at the top is right.
autocmd("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(args)
    local buf = args.buf
    if vim.bo[buf].filetype == "gitcommit" or vim.b[buf].last_loc_done then return end
    vim.b[buf].last_loc_done = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- q closes transient windows ----------------------------------------------
-- Help, quickfix, checkhealth and friends: q closes the window and drops the
-- buffer. buflisted=false keeps them out of :ls and buffer cycling.
autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = { "help", "qf", "checkhealth", "man", "lspinfo", "startuptime", "notify", "grug-far" },
  callback = function(args)
    vim.bo[args.buf].buflisted = false
    -- Deferred so it wins over any q the filetype's own ftplugin sets.
    vim.schedule(function()
      vim.keymap.set("n", "q", function()
        vim.cmd("close")
        pcall(vim.api.nvim_buf_delete, args.buf, { force = true })
      end, { buffer = args.buf, silent = true, desc = "Close" })
    end)
  end,
})

-- Prose filetypes wrap and spell-check -----------------------------------
autocmd("FileType", {
  group = augroup("wrap_spell"),
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- JSON shows its quotes ---------------------------------------------------
-- conceallevel=2 (global, for markdown) would hide the quotes in JSON.
autocmd("FileType", {
  group = augroup("json_conceal"),
  pattern = { "json", "jsonc", "json5" },
  callback = function() vim.opt_local.conceallevel = 0 end,
})

-- Create missing directories on save -------------------------------------
-- :w path/to/new/file.lua works even if path/to/new does not exist yet.
-- Skips URLs like oil:// or scp:// (scheme followed by //).
autocmd("BufWritePre", {
  group = augroup("auto_create_dir"),
  callback = function(args)
    if args.match:match("^%w%w+:[\\/][\\/]") then return end
    local file = vim.uv.fs_realpath(args.match) or args.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- Command-line window ------------------------------------------------------
-- q: in normal mode opens the command-line history window, almost always by
-- accident when aiming for :q. Close it immediately.
autocmd("CmdWinEnter", {
  group = augroup("no_cmdwin"),
  callback = function() vim.cmd("quit") end,
})
