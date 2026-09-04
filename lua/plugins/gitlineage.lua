-- gitlineage: select lines, <leader>gl, get the commits that touched exactly
-- those lines (git log -L) in a split. Needs diffview for opening a commit.
require("gitlineage").setup({
  split = "auto",
  keymap = "<leader>gl", -- the plugin maps this in normal and visual mode itself
  keys = {
    close = "q",
    next_commit = "]c",
    prev_commit = "[c",
    -- The plugin's versions only work with the cursor exactly on the
    -- `commit <sha>` header. Replaced below with ones that find the header
    -- of whichever commit block the cursor is in.
    yank_commit = nil,
    open_diff = nil,
  },
})

-- The sha of the commit block containing the cursor: nearest `commit` header
-- at or above the current line. Vim pattern, so \x for a hex digit.
local function commit_at_cursor()
  local lnum = vim.fn.search([[^commit \x]], "bcnW")
  if lnum == 0 then return nil end
  return vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]:match("^commit (%x+)")
end

-- The lineage buffer is named before its window opens, so BufWinEnter sees
-- the gitlineage:// name.
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = vim.api.nvim_create_augroup("config_gitlineage", { clear = true }),
  pattern = "gitlineage://*",
  callback = function(args)
    vim.keymap.set("n", "<CR>", function()
      local sha = commit_at_cursor()
      if not sha then return vim.notify("gitlineage: no commit here", vim.log.levels.WARN) end
      -- Root commit has no parent to diff against; diffview then diffs
      -- against the empty tree.
      vim.fn.system({ "git", "rev-parse", "--verify", "--quiet", sha .. "^" })
      vim.cmd("DiffviewOpen " .. sha .. (vim.v.shell_error == 0 and "^!" or ""))
    end, { buffer = args.buf, desc = "Open commit in Diffview" })

    vim.keymap.set("n", "yc", function()
      local sha = commit_at_cursor()
      if not sha then return vim.notify("gitlineage: no commit here", vim.log.levels.WARN) end
      vim.fn.setreg('"', sha)
      vim.fn.setreg("+", sha)
      vim.notify("gitlineage: yanked " .. sha:sub(1, 8), vim.log.levels.INFO)
    end, { buffer = args.buf, desc = "Yank commit SHA" })
  end,
})
