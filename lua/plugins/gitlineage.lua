return {
  {
    "lionyxml/gitlineage.nvim",
    dependencies = { "sindrets/diffview.nvim" },
    keys = { { "<leader>gl", mode = "v", desc = "Git Line History" } },
    config = function()
      require("gitlineage").setup({
        split = "auto",
        keymap = "<leader>gl",
        keys = {
          close = "q",
          next_commit = "]c",
          prev_commit = "[c",
          yank_commit = "yc",
          open_diff = "<CR>",
        },
      })
    end,
  },
}
