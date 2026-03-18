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
      scroll = { enabled = true },
      explorer = { enabled = false },
      picker = {
        sources = {
          files = {
            hidden = true,
            ignored = true,
          },
          grep = {
            hidden = true,
            ignored = true,
          },
        },
      },
    },
  },
}
