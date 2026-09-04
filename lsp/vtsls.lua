-- TypeScript and JavaScript via vtsls, a wrapper around the same engine
-- VS Code uses. Root is the package lockfile's directory, so monorepo
-- packages each get their own instance.
return {
  cmd = { "vtsls", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  root_markers = { { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" }, { ".git" } },
  init_options = { hostInfo = "neovim" },
  settings = {
    typescript = { updateImportsOnFileMove = { enabled = "always" } },
    javascript = { updateImportsOnFileMove = { enabled = "always" } },
    vtsls = { enableMoveToFileCodeAction = true },
  },
}
