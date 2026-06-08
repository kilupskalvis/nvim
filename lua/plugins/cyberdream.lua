return {
  {
    "scottmckendry/cyberdream.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      transparent = true,
      italic_comments = true,
      variant = "auto",
      overrides = function(_)
        if vim.o.background == "light" then
          return { CursorLine = { bg = "#e8e8e8" } }
        else
          return { CursorLine = { bg = "#2a2a2a" } }
        end
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "cyberdream",
    },
  },
}
