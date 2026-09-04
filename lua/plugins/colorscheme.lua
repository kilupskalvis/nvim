require("cyberdream").setup({
  transparent = true,      -- terminal background shows through
  italic_comments = true,
  variant = "auto",        -- follows 'background' (dark/light)
  overrides = function(_)
    -- Cyberdream's cursorline is too faint against a transparent background.
    if vim.o.background == "light" then
      return { CursorLine = { bg = "#e8e8e8" } }
    end
    return { CursorLine = { bg = "#2a2a2a" } }
  end,
})

-- Apply it. Errors here mean the plugin did not install.
vim.cmd.colorscheme("cyberdream")

vim.keymap.set("n", "<leader>ut", "<cmd>CyberdreamToggleMode<cr>", { desc = "Toggle dark/light mode" })
