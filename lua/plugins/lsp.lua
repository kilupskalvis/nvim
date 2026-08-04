return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = false },
      servers = {
        -- K is remapped to "move 20 lines up" in lua/config/keymaps.lua.
        -- Disable LazyVim's buffer-local hover keymap; snacks re-applies these
        -- on a debounce, so deleting it after LspAttach loses the race.
        -- Hover lives on <leader>k instead.
        ["*"] = {
          keys = {
            { "K", false },
          },
        },
        gopls = {
          settings = {
            gopls = {
              usePlaceholders = false,
              hints = {
                assignVariableTypes = false,
                compositeLiteralFields = false,
                compositeLiteralTypes = false,
                constantValues = false,
                functionTypeParameters = false,
                parameterNames = false,
                rangeVariableTypes = false,
              },
            },
          },
        },
        lua_ls = {
          settings = {
            Lua = {
              completion = {
                callSnippet = "Disable",
              },
            },
          },
        },
      },
    },
  },
  {
    "mrcjkb/rustaceanvim",
    optional = true,
    opts = {
      server = {
        default_settings = {
          ["rust-analyzer"] = {
            completion = {
              callable = {
                snippets = "add_parentheses",
              },
            },
          },
        },
      },
    },
  },
}
