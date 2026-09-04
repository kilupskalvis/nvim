-- blink.cmp: the completion popup. Gathers candidates from the sources below,
-- fuzzy-ranks them with a prebuilt Rust matcher (downloaded on first run, Lua
-- fallback if that fails), shows docs beside the menu, expands snippets via
-- Neovim's built-in vim.snippet.
require("blink.cmp").setup({
  -- Explicit keys, no preset. Each key is a list of commands tried in
  -- order; "fallback" means "do what the key normally does".
  keymap = {
    preset = "none",
    ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
    ["<C-e>"] = { "cancel", "fallback" },       -- undo auto-inserted text and close
    ["<CR>"] = { "accept", "fallback" },        -- Enter accepts, or newline if no menu
    -- Tab walks the menu; if no menu but a snippet is active, jump to its
    -- next placeholder; else a normal Tab.
    ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
    ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
    -- hjkl-shaped: bare j/k are letters in insert mode, so Ctrl.
    ["<C-j>"] = { "select_next", "fallback" },
    ["<C-k>"] = { "select_prev", "fallback" },
    ["<C-n>"] = { "select_next", "fallback" },
    ["<C-p>"] = { "select_prev", "fallback" },
    ["<C-d>"] = { "scroll_documentation_down", "fallback" },
    ["<C-u>"] = { "scroll_documentation_up", "fallback" },
  },

  appearance = {
    nerd_font_variant = "mono",
  },

  completion = {
    list = {
      selection = {
        preselect = false,   -- nothing selected until you move; Enter then inserts a newline
        auto_insert = true,  -- moving through the list previews the item in the buffer
      },
    },
    menu = {
      border = "rounded",
      draw = {
        -- kind icon, label, then the source/kind name on the right
        columns = { { "kind_icon" }, { "label", "label_description", gap = 1 }, { "kind" } },
      },
    },
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 200,
      window = { border = "rounded" },
    },
    ghost_text = { enabled = false },
  },

  -- Parameter hints while typing a call.
  signature = { enabled = true, window = { border = "rounded" } },

  sources = {
    default = { "lazydev", "lsp", "path", "snippets", "buffer" },
    providers = {
      -- require("...") completion for this config's modules and Neovim's
      -- runtime, ranked above lua_ls's own guesses.
      lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
    },
  },

  fuzzy = { implementation = "prefer_rust_with_warning" },

  -- Command-line completion stays Neovim's wildmenu for now.
  cmdline = { enabled = false },
})

-- Servers must be told the client supports snippets, resolve-on-demand and
-- the rest, or they send plain items. "*" applies to every lsp/*.lua config;
-- it merges with each server's own capabilities table. Runs before any
-- server starts because plugins.completion loads before plugins.lsp.
vim.lsp.config("*", {
  capabilities = require("blink.cmp").get_lsp_capabilities(),
})
