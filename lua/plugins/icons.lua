-- mini.icons provides the file and filetype glyphs. Plugins written against
-- nvim-web-devicons (oil, bufferline, trouble, lualine) call that API; the
-- mock answers those calls with mini's glyphs and colors, so every plugin
-- draws the same icon set. This is what the LazyVim config did.
require("mini.icons").setup({
  file = {
    [".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
    ["devcontainer.json"] = { glyph = "", hl = "MiniIconsAzure" },
  },
  filetype = {
    dotenv = { glyph = "", hl = "MiniIconsYellow" },
  },
})
MiniIcons.mock_nvim_web_devicons()
