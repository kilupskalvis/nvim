-- Lua. Knowledge of the `vim` API inside this config comes from lazydev
-- (plugin), which injects Neovim's runtime into the workspace library.
return {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { { ".luarc.json", ".luarc.jsonc" }, { ".stylua.toml", "stylua.toml", "selene.toml" }, { ".git" } },
  settings = {
    Lua = {
      workspace = { checkThirdParty = false },
      codeLens = { enable = true },
      completion = { callSnippet = "Replace" },
      hint = { enable = true, semicolon = "Disable" },
      doc = { privateName = { "^_" } },
    },
  },
}
