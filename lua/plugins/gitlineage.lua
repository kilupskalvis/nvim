return {
  {
    "lionyxml/gitlineage.nvim",
    dependencies = { "sindrets/diffview.nvim" },
    -- The plugin maps its key in both modes (gitlineage.lua sets { "n", "v" }),
    -- so declare both here too. With only the visual trigger, normal mode had
    -- nothing to lazy-load the plugin and stayed unmapped until the first
    -- visual-mode use. Claiming both modes also stops LazyVim from installing
    -- its own <leader>gl, since safe_keymap_set skips keys lazy already has.
    keys = { { "<leader>gl", mode = { "n", "v" }, desc = "Git Line History" } },
    config = function()
      require("gitlineage").setup({
        split = "auto",
        keymap = "<leader>gl",
        keys = {
          close = "q",
          next_commit = "]c",
          prev_commit = "[c",
          -- The plugin's versions only work with the cursor exactly on the
          -- `commit <sha>` header. Replaced below with ones that find the
          -- header of whichever commit block the cursor is in.
          yank_commit = nil,
          open_diff = nil,
        },
      })

      -- The sha of the commit block containing the cursor: nearest `commit`
      -- header at or above the current line.
      local function commit_at_cursor()
        local lnum = vim.fn.search([[^commit \x]], "bcnW")
        if lnum == 0 then return nil end
        return vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]:match("^commit (%x+)")
      end

      -- The lineage buffer is named before its window opens, so BufWinEnter
      -- sees the gitlineage:// name.
      vim.api.nvim_create_autocmd("BufWinEnter", {
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
    end,
  },
}
