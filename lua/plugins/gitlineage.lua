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
          yank_commit = "yc",
          open_diff = "<CR>",
        },
      })
    end,
  },
}
