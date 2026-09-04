-- conform.nvim: one entry point for formatting. Picks the formatter for the
-- buffer's filetype from the table below, falls back to the language server
-- when the table has no entry (rust-analyzer, yaml-language-server, taplo
-- all format through LSP). Formatters are Mason-installed binaries on PATH.
local conform = require("conform")

conform.setup({
  formatters_by_ft = {
    lua = { "stylua" },
    go = { "goimports", "gofumpt" },       -- imports first, then stricter gofmt
    python = { "ruff_organize_imports", "ruff_format" },
    c = { "clang-format" },
    cpp = { "clang-format" },
    sh = { "shfmt" },
    bash = { "shfmt" },
    zsh = { "shfmt" },
    htmldjango = { "djlint" },
    -- prettier for the web stack; LSP fallback would also work for most
    css = { "prettier" },
    scss = { "prettier" },
    less = { "prettier" },
    html = { "prettier" },
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    vue = { "prettier" },
    json = { "prettier" },
    jsonc = { "prettier" },
    yaml = { "prettier" },
    graphql = { "prettier" },
    handlebars = { "prettier" },
    markdown = { "prettier" },
    ["markdown.mdx"] = { "prettier" },
    -- "_" would apply to every filetype without an entry; left unset so LSP
    -- fallback handles those.
  },
  default_format_opts = {
    timeout_ms = 3000,
    async = false,
    quiet = false,
    lsp_format = "fallback",  -- LSP formats only when no formatter is listed
  },
  -- Format on save, unless disabled globally (vim.g) or for this buffer (vim.b).
  format_on_save = function(bufnr)
    if vim.g.autoformat == false or vim.b[bufnr].autoformat == false then return end
    return { timeout_ms = 3000, lsp_format = "fallback" }
  end,
  formatters = {
    -- prettier only when the project has a config; otherwise unstyled
    -- projects get reformatted against their will on save.
    prettier = {
      condition = function(_, ctx)
        return vim.fs.root(ctx.dirname, {
          ".prettierrc", ".prettierrc.json", ".prettierrc.yml", ".prettierrc.yaml", ".prettierrc.js",
          ".prettierrc.cjs", ".prettierrc.mjs", ".prettierrc.toml", "prettier.config.js",
          "prettier.config.cjs", "prettier.config.mjs",
        }) ~= nil or vim.fs.root(ctx.dirname, { "package.json" }) ~= nil
      end,
    },
  },
})

-- gq uses conform, so formatting a motion works too.
vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

-- Keymaps -------------------------------------------------------------------
local map = vim.keymap.set
map({ "n", "x" }, "<leader>cf", function() conform.format() end, { desc = "Format" })
-- Format only the embedded code blocks, e.g. lua/python fences in markdown.
map({ "n", "x" }, "<leader>cF", function() conform.format({ formatters = { "injected" }, timeout_ms = 3000 }) end, { desc = "Format injected languages" })

-- Unset means on; false means off. `x == false` flips it: off -> true, on -> false.
-- (Not `cond and false or true`: with `false` in the middle that idiom always
-- returns true.)
map("n", "<leader>uf", function()
  vim.g.autoformat = vim.g.autoformat == false
  vim.notify("Format on save: " .. (vim.g.autoformat and "on" or "off"))
end, { desc = "Toggle format on save (global)" })
map("n", "<leader>uF", function()
  vim.b.autoformat = vim.b.autoformat == false
  vim.notify("Format on save (buffer): " .. (vim.b.autoformat and "on" or "off"))
end, { desc = "Toggle format on save (buffer)" })

-- :ConformInfo shows which formatter applies to the current buffer and why.
