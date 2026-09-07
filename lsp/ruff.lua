-- Python linter and formatter as a language server: diagnostics, code
-- actions (fix, organize imports) and formatting. Hover is left to
-- pyright, see the LspAttach handler.
return {
  cmd = { "ruff", "server" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
}
