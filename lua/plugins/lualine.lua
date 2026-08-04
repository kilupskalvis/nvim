return {
  {
    "nvim-lualine/lualine.nvim",
    -- Drop LazyVim's clock from the bottom right (lualine_z).
    opts = function(_, opts)
      opts.sections = opts.sections or {}
      opts.sections.lualine_z = {}
    end,
  },
}
