return {
  { "catppuccin/nvim", enabled = false },
  { "folke/tokyonight.nvim", enabled = false },
  {
    "folke/which-key.nvim",
    opts = {
      defaults = {},
      spec = {
        { "<leader>d", hidden = true },
      },
    },
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
      scroll = { enabled = true },
      explorer = { enabled = false },
      picker = {
        sources = {
          files = {
            hidden = true,
            ignored = true,
            exclude = { ".venv", "node_modules", "__pycache__", ".git", "vendor" },
          },
          grep = {
            hidden = true,
            ignored = true,
            exclude = { ".venv", "node_modules", "__pycache__", ".git", "vendor" },
          },
        },
      },
    },
  },
}
