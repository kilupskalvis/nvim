-- snacks.nvim is a bundle of independent modules; only the ones enabled here
-- do anything. Enabled now: picker (fuzzy finder for everything), bigfile,
-- quickfile, input (nicer vim.ui.input, used by rename), notifier
-- (vim.notify as popups), terminal (Claude toggle), git (blame line).
-- Left off until the UI step: dashboard, indent, scope, words, statuscolumn.
-- Left off for good: scroll (animated scrolling), explorer (oil instead).
require("snacks").setup({
  bigfile = {
    enabled = true,
    -- Hand-written code stays under ~400KB; above that it is generated
    -- files, where LSP and treesitter only cause freezes. Default was 1.5MB.
    size = 500 * 1024,
    setup = function(ctx)
      if vim.fn.exists(":NoMatchParen") ~= 0 then vim.cmd("NoMatchParen") end
      Snacks.util.wo(0, { foldmethod = "manual", statuscolumn = "", conceallevel = 0 })
      vim.b.completion = false -- blink reads this
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(ctx.buf) then return end
        vim.treesitter.stop(ctx.buf)
        vim.bo[ctx.buf].swapfile = false
        vim.bo[ctx.buf].undofile = false
        vim.bo[ctx.buf].undolevels = -1
        for _, client in ipairs(vim.lsp.get_clients({ bufnr = ctx.buf })) do
          vim.lsp.buf_detach_client(ctx.buf, client.id)
        end
      end)
    end,
  },
  quickfile = { enabled = true }, -- render the file before plugins load when opened from the shell
  input = { enabled = true },
  notifier = { enabled = true, timeout = 3000 },
  terminal = { win = { position = "bottom" } },
  scroll = { enabled = false },
  explorer = { enabled = false },
  indent = { enabled = true },  -- indent guides, current scope highlighted
  scope = { enabled = true },   -- ii / ai text objects and ]i [i jumps on scope
  words = { enabled = true },   -- highlight other references of the word under cursor (LSP)
  dashboard = {
    enabled = true,
    preset = {
      header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
      -- No `g` entry: with bare-letter shortcuts, <leader>g timing out on the
      -- dashboard ran "Find Text" instead of reaching <leader>gd / <leader>gh.
      keys = {
        { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
        { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
        { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
        { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
        { icon = "󰏗 ", key = "m", desc = "Mason", action = ":Mason" },
        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
      },
    },
    -- The default third section is "startup", which reads lazy.nvim's
    -- timing stats and errors without lazy.nvim. Header and keys only.
    -- (Recent files are one keypress away: r, or <leader>fr.)
    sections = {
      { section = "header" },
      { section = "keys", gap = 1, padding = 1 },
    },
  },

  picker = {
    -- Ranking. Both cost a path normalisation per item, negligible once
    -- .gitignore is respected below.
    matcher = {
      frecency = true,  -- files you actually open rank first
      cwd_bonus = true, -- files under the cwd beat files outside it
    },
    sources = {
      -- files keeps ignored = true so gitignored files like .env still show;
      -- a path list is cheap to skim. The exclude list trims the worst.
      files = {
        hidden = true,
        ignored = true,
        exclude = { ".venv", "node_modules", "__pycache__", ".git", "vendor" },
      },
      -- grep respects .gitignore: --no-ignore buried real hits under
      -- site-packages and build output. .env excluded so secrets are not
      -- grepped by accident; .git because hidden makes rg descend into it.
      grep = {
        hidden = true,
        ignored = false,
        args = { "--glob=!.git", "--glob=!.env*" },
      },
    },
    win = {
      input = {
        keys = {
          -- readline-style editing in the prompt
          ["<C-u>"] = { function() vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-u>", true, false, true), "n", false) end, mode = "i", desc = "Kill to start of line" },
          ["<C-k>"] = { function()
            local col = vim.fn.col(".")
            vim.api.nvim_set_current_line(vim.api.nvim_get_current_line():sub(1, col - 1))
          end, mode = "i", desc = "Kill to end of line" },
          ["<C-a>"] = { function() vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Home>", true, false, true), "n", false) end, mode = "i", desc = "Start of line" },
          ["<C-e>"] = { function() vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<End>", true, false, true), "n", false) end, mode = "i", desc = "End of line" },
          -- Bigger-unit list movement, the picker's version of J/K. Letters
          -- only in normal mode: the prompt is insert mode where they are text.
          ["J"] = { "list_scroll_down", mode = "n", desc = "Scroll list down" },
          ["K"] = { "list_scroll_up", mode = "n", desc = "Scroll list up" },
          ["<S-Down>"] = { "list_scroll_down", mode = { "i", "n" }, desc = "Scroll list down" },
          ["<S-Up>"] = { "list_scroll_up", mode = { "i", "n" }, desc = "Scroll list up" },
        },
      },
    },
  },
})

-- Keymaps -------------------------------------------------------------------
local map = vim.keymap.set
local p = Snacks.picker

-- Files and grep default to the git root when inside a repo, else cwd.
local function root() return Snacks.git.get_root() or vim.uv.cwd() end

map("n", "<leader><space>", function() p.files({ cwd = root() }) end, { desc = "Find files (root)" })
map("n", "<leader>ff", function() p.files({ cwd = root() }) end, { desc = "Find files (root)" })
map("n", "<leader>fF", function() p.files() end, { desc = "Find files (cwd)" })
map("n", "<leader>fg", function() p.git_files() end, { desc = "Find files (git)" })
map("n", "<leader>fr", function() p.recent() end, { desc = "Recent files" })
map("n", "<leader>fR", function() p.recent({ filter = { cwd = true } }) end, { desc = "Recent files (cwd)" })
map("n", "<leader>fc", function() p.files({ cwd = vim.fn.stdpath("config") }) end, { desc = "Find config file" })
map("n", "<leader>fp", function() p.projects() end, { desc = "Projects" })
map("n", "<leader>,", function() p.buffers() end, { desc = "Buffers" })
map("n", "<leader>fb", function() p.buffers() end, { desc = "Buffers" })

map("n", "<leader>/", function() p.grep({ cwd = root() }) end, { desc = "Grep (root)" })
map("n", "<leader>sg", function() p.grep({ cwd = root() }) end, { desc = "Grep (root)" })
map("n", "<leader>sG", function() p.grep() end, { desc = "Grep (cwd)" })
map({ "n", "x" }, "<leader>sw", function() p.grep_word({ cwd = root() }) end, { desc = "Grep word or selection" })
map("n", "<leader>sb", function() p.lines() end, { desc = "Buffer lines" })
map("n", "<leader>sB", function() p.grep_buffers() end, { desc = "Grep open buffers" })

map("n", "<leader>ss", function() p.lsp_symbols() end, { desc = "LSP symbols" })
map("n", "<leader>sS", function() p.lsp_workspace_symbols() end, { desc = "LSP workspace symbols" })
map("n", "<leader>sd", function() p.diagnostics() end, { desc = "Diagnostics" })
map("n", "<leader>sD", function() p.diagnostics_buffer() end, { desc = "Buffer diagnostics" })

map("n", "<leader>gs", function() p.git_status() end, { desc = "Git status" })
map("n", "<leader>gS", function() p.git_stash() end, { desc = "Git stash" })
map("n", "<leader>gc", function() p.git_log() end, { desc = "Git log" })
-- <leader>gd, <leader>gf, <leader>gh, <leader>gl belong to diffview and gitlineage.

map("n", "<leader>:", function() p.command_history() end, { desc = "Command history" })
map("n", "<leader>sc", function() p.commands() end, { desc = "Commands" })
map("n", "<leader>sh", function() p.help() end, { desc = "Help pages" })
map("n", "<leader>sk", function() p.keymaps() end, { desc = "Keymaps" })
map("n", "<leader>sa", function() p.autocmds() end, { desc = "Autocmds" })
map("n", "<leader>sH", function() p.highlights() end, { desc = "Highlights" })
map("n", "<leader>si", function() p.icons() end, { desc = "Icons" })
map("n", "<leader>sj", function() p.jumps() end, { desc = "Jumps" })
map("n", "<leader>sm", function() p.marks() end, { desc = "Marks" })
map("n", "<leader>sM", function() p.man() end, { desc = "Man pages" })
map("n", "<leader>sq", function() p.qflist() end, { desc = "Quickfix list" })
map("n", "<leader>sl", function() p.loclist() end, { desc = "Location list" })
map("n", "<leader>su", function() p.undo() end, { desc = "Undo tree" })
map("n", "<leader>sR", function() p.resume() end, { desc = "Resume last picker" })
map("n", "<leader>uC", function() p.colorschemes() end, { desc = "Colorschemes" })
map("n", "<leader>n", function() p.notifications() end, { desc = "Notification history" })

-- :Dashboard reopens the start screen in the current window. Bare open()
-- makes a fullscreen float, and files opened later from an oil float landed
-- back inside that float.
vim.api.nvim_create_user_command("Dashboard", function()
  Snacks.dashboard.open({ win = 0 })
end, {})

-- Terminal and git helpers ----------------------------------------------
map("n", "<leader>cc", function() Snacks.terminal("claude") end, { desc = "Claude Code (toggle)" })
map("n", "<leader>ft", function() Snacks.terminal() end, { desc = "Terminal (toggle)" })

map("n", "<leader>gb", function()
  if vim.api.nvim_buf_get_name(0):match("^diffview://") then
    return vim.notify("Git blame not available in diffview", vim.log.levels.WARN)
  end
  Snacks.git.blame_line()
end, { desc = "Git blame line" })
