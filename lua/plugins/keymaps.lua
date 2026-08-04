return {
  {
    -- H/L are remapped to word motions in lua/config/keymaps.lua. Buffer
    -- cycling stays on [b / ]b and <leader><Left> / <leader><Right>.
    "akinsho/bufferline.nvim",
    keys = {
      { "<S-h>", false },
      { "<S-l>", false },
    },
  },
  {
    "gbprod/yanky.nvim",
    keys = {
      { "d", [["_d]], mode = { "n", "v" }, desc = "Delete (black hole)" },
      { "D", [["_D]], mode = { "n", "v" }, desc = "Delete to EOL (black hole)" },
      { "c", [["_c]], mode = { "n", "v" }, desc = "Change (black hole)" },
      { "C", [["_C]], mode = { "n", "v" }, desc = "Change to EOL (black hole)" },
      { "x", [["_x]], mode = { "n", "v" }, desc = "Delete char (black hole)" },
    },
  },
}
