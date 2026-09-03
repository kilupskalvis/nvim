return {
  { "catppuccin/nvim", enabled = false },
  { "folke/tokyonight.nvim", enabled = false },
  { "folke/which-key.nvim", enabled = false },
  {
    -- Dashboard shortcuts are bare letters, so the default `g` (Find Text) is
    -- what runs when <leader>g times out there, instead of reaching the git
    -- bindings like <leader>gd / <leader>gh. Grep is on <leader>/ and
    -- <leader>sg anyway, so drop the dashboard entry.
    "folke/snacks.nvim",
    opts = function(_, opts)
      local keys = vim.tbl_get(opts, "dashboard", "preset", "keys")
      if keys then
        opts.dashboard.preset.keys = vim.tbl_filter(function(item)
          return item.key ~= "g"
        end, keys)
      end
    end,
  },
  {
    "folke/snacks.nvim",
    keys = {
      -- Disable snacks explorer (replaced by oil.nvim)
      { "<leader>e", false },
      { "<leader>E", false },
      -- Disable snacks_picker's <leader>gd so diffview can handle it
      { "<leader>gd", false },
    },
    opts = {
      dashboard = {
        enabled = true,
        preset = {
          header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
          ]],
        },
      },
      bigfile = {
        enabled = true,
        -- Hand-written code stays under ~400KB; above that it's generated
        -- files, where LSP/treesitter only cause freezes. Default was 1.5MB.
        size = 500 * 1024,
        ---@param ctx {buf: number, ft: string}
        setup = function(ctx)
          if vim.fn.exists(":NoMatchParen") ~= 0 then
            vim.cmd([[NoMatchParen]])
          end
          Snacks.util.wo(0, { foldmethod = "manual", statuscolumn = "", conceallevel = 0 })
          vim.b.completion = false
          vim.b.minianimate_disable = true
          vim.b.minihipatterns_disable = true
          vim.b.miniindentscope_disable = true
          vim.b.minidiff_disable = true
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(ctx.buf) then
              vim.treesitter.stop(ctx.buf)
              vim.bo[ctx.buf].swapfile = false
              vim.bo[ctx.buf].undofile = false
              vim.bo[ctx.buf].undolevels = -1
              -- Detach any LSP clients that managed to attach
              for _, client in ipairs(vim.lsp.get_clients({ bufnr = ctx.buf })) do
                vim.lsp.buf_detach_client(ctx.buf, client.id)
              end
            end
          end)
        end,
      },
      lazygit = { enabled = false },
      -- Animated scrolling queues wheel ticks behind a 200ms animation, so
      -- the view lags the hand and clicks land on whatever line was passing.
      scroll = { enabled = false },
      explorer = { enabled = false },
      picker = {
        win = {
          input = {
            keys = {
              ["<C-u>"] = {
                function()
                  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-u>", true, false, true), "n", false)
                end,
                mode = "i",
                desc = "Kill to start of line",
              },
              ["<C-k>"] = {
                function()
                  local col = vim.fn.col(".")
                  local line = vim.api.nvim_get_current_line()
                  vim.api.nvim_set_current_line(line:sub(1, col - 1))
                end,
                mode = "i",
                desc = "Kill to end of line",
              },
              ["<C-a>"] = {
                function()
                  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Home>", true, false, true), "n", false)
                end,
                mode = "i",
                desc = "Start of line",
              },
              ["<C-e>"] = {
                function()
                  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<End>", true, false, true), "n", false)
                end,
                mode = "i",
                desc = "End of line",
              },
              -- Bigger-unit list movement, the picker's version of the tier that
              -- J/K and S-Arrows occupy in nvim and tmux. The letters are normal
              -- mode only: the prompt is insert mode, where J and K are literal
              -- characters, so there is nowhere else to put them. snacks already
              -- provides j/k, gg and G in this window's normal mode.
              ["J"] = { "list_scroll_down", mode = "n", desc = "Scroll list down" },
              ["K"] = { "list_scroll_up", mode = "n", desc = "Scroll list up" },
              ["<S-Down>"] = { "list_scroll_down", mode = { "i", "n" }, desc = "Scroll list down" },
              ["<S-Up>"] = { "list_scroll_up", mode = { "i", "n" }, desc = "Scroll list up" },
            },
          },
        },
        -- Ranking. Both are off by default because they cost path normalisation
        -- per item, which only matters on huge result sets -- and results stop
        -- being huge once .gitignore is respected below.
        matcher = {
          frecency = true, -- files you actually open rank first
          cwd_bonus = true, -- files under the cwd beat files outside it
        },
        sources = {
          -- The two sources are deliberately asymmetric.
          --
          -- files keeps `ignored = true` (--no-ignore) so gitignored files like
          -- .env still appear in the normal file list. A path list is cheap to
          -- skim even when it includes junk, and there is no way to respect
          -- .gitignore while re-including one file: fd ignores positive globs
          -- for ignored paths, and rg treats a positive glob as a whitelist
          -- that filters out everything else. So the exclude list below stays,
          -- imperfect as it is.
          files = {
            hidden = true,
            ignored = true,
            exclude = { ".venv", "node_modules", "__pycache__", ".git", "vendor" },
          },
          -- grep is where --no-ignore actually hurt: thousands of matching
          -- lines from site-packages and build output, burying the real hits.
          -- Respecting .gitignore here is what fixed that. .env is excluded on
          -- top, since grepping secrets is not something to do by accident, and
          -- .git because `hidden` makes ripgrep descend into it.
          grep = {
            hidden = true,
            ignored = false,
            args = { "--glob=!.git", "--glob=!.env*" },
          },
        },
      },
    },
  },
}
