-- Mason downloads language servers, formatters, linters and the tree-sitter
-- CLI into ~/.local/share/nvim-next/mason and prepends its bin/ to PATH while
-- nvim runs. Principle behind using it: clone the dotfiles on any machine,
-- open nvim, everything installs itself. The only prerequisites are the
-- runtimes Mason builds on: git, a C compiler, node, python3, go.
--
-- Mason is a downloader here, nothing more. No mason-lspconfig, no automatic
-- server wiring. The LSP side reads lsp/*.lua and finds binaries on PATH.
--
-- :Mason opens the UI. :MasonUpdate refreshes the registry.
require("mason").setup({
  ui = { border = "rounded" },
})

-- Everything the config expects on PATH, by Mason package name
-- (:Mason lists them; names differ from binaries, e.g. json-lsp).
local tools = {
  -- tree-sitter parsers are compiled with this
  "tree-sitter-cli",
  -- language servers
  "lua-language-server",
  "gopls",
  "basedpyright",
  "ruff",
  "django-language-server", -- Django Python side: models, urls, settings
  "django-template-lsp",    -- Django templates: tags, filters, template paths
  "rust-analyzer",
  "vtsls",
  "eslint-lsp",
  "json-lsp",
  "html-lsp",
  "css-lsp",
  "yaml-language-server",
  "tailwindcss-language-server",
  "bash-language-server",
  "dockerfile-language-server",
  "docker-compose-language-service",
  "marksman",
  "taplo",
  "clangd",
  -- formatters
  "stylua",
  "gofumpt",
  "goimports",
  "prettier",
  "clang-format",
  "shfmt",
  -- linters
  "golangci-lint",
  "markdownlint-cli2",
  "hadolint",
  "djlint", -- Django/Jinja template linter and formatter
}

-- Install whatever is missing. The registry is a package index Mason keeps
-- in its cache; on a fresh machine it must be fetched first, hence refresh()
-- with a callback. Installs run in the background and report in :Mason.
local registry = require("mason-registry")
local function install_missing()
  local missing = {}
  for _, name in ipairs(tools) do
    if not registry.has_package(name) then
      vim.notify("mason: unknown package " .. name, vim.log.levels.WARN)
    elseif not registry.is_installed(name) then
      table.insert(missing, name)
    end
  end
  if #missing == 0 then return end
  vim.notify("mason: installing " .. table.concat(missing, ", "), vim.log.levels.INFO)
  for _, name in ipairs(missing) do
    registry.get_package(name):install()
  end
end
registry.refresh(install_missing)
