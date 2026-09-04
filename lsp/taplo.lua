-- TOML, with schema validation for Cargo.toml and pyproject.toml.
return {
  cmd = { "taplo", "lsp", "stdio" },
  filetypes = { "toml" },
  root_markers = { ".taplo.toml", "taplo.toml", ".git" },
}
