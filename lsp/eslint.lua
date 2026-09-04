-- ESLint as a server: diagnostics from the project's own eslint config.
-- workspace_required: never start without a project root. The root
-- function refuses when no eslint config exists, so projects without
-- ESLint get no client at all.
local config_files = {
  ".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.yaml", ".eslintrc.yml", ".eslintrc.json",
  "eslint.config.js", "eslint.config.mjs", "eslint.config.cjs", "eslint.config.ts", "eslint.config.mts", "eslint.config.cts",
}
return {
  cmd = { "vscode-eslint-language-server", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte", "astro" },
  workspace_required = true,
  root_dir = function(bufnr, on_dir)
    local project = vim.fs.root(bufnr, { { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" }, { ".git" } })
    if not project then return end
    if not vim.fs.root(bufnr, config_files) then return end
    on_dir(project)
  end,
  settings = {
    validate = "on",
    run = "onType",
    format = true,
    workingDirectory = { mode = "auto" },
    codeAction = {
      disableRuleComment = { enable = true, location = "separateLine" },
      showDocumentation = { enable = true },
    },
  },
  before_init = function(_, config)
    -- The server wants to know the workspace folder explicitly.
    if config.root_dir then
      config.settings = config.settings or {}
      config.settings.workspaceFolder = {
        uri = vim.uri_from_fname(config.root_dir),
        name = vim.fn.fnamemodify(config.root_dir, ":t"),
      }
    end
  end,
  on_attach = function(client, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, "LspEslintFixAll", function()
      client:request_sync("workspace/executeCommand", {
        command = "eslint.applyAllFixes",
        arguments = { { uri = vim.uri_from_bufnr(bufnr), version = vim.lsp.util.buf_versions[bufnr] } },
      }, nil, bufnr)
    end, { desc = "Fix all ESLint problems" })
  end,
}
