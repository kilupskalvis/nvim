-- LazyVim only runs `checktime` on FocusGained, TermClose and TermLeave
-- (LazyVim/lua/lazyvim/config/autocmds.lua:8). `autoread` never polls on its
-- own, so a file rewritten by an agent while nvim already has focus keeps
-- showing stale text until you switch away and come back. CursorHold closes
-- that gap: it fires once after 'updatetime' of inactivity, not repeatedly, and
-- checktime is a stat() per loaded buffer -- measured at 0.001ms with 16
-- buffers open.
vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI", "BufEnter" }, {
  group = vim.api.nvim_create_augroup("checktime_extra", { clear = true }),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

-- Announce reloads. Without this the buffer changes under the cursor with no
-- explanation, which is worse than the staleness it fixes. A modified buffer is
-- never silently clobbered -- nvim raises W12 and asks instead.
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = vim.api.nvim_create_augroup("checktime_notify", { clear = true }),
  callback = function(args)
    local name = vim.api.nvim_buf_get_name(args.buf)
    vim.notify(
      ("Reloaded from disk: %s"):format(vim.fn.fnamemodify(name, ":~:.")),
      vim.log.levels.INFO
    )
  end,
})
