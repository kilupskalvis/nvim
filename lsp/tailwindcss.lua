-- Tailwind class completion and lint. Starts only in projects that have a
-- tailwind or postcss config (workspace_required + root_dir), so it never
-- runs in plain HTML or markdown.
return {
  cmd = { "tailwindcss-language-server", "--stdio" },
  filetypes = {
    "html", "htmldjango", "css", "scss", "less", "postcss",
    "javascript", "javascriptreact", "typescript", "typescriptreact",
    "vue", "svelte", "astro",
  },
  workspace_required = true,
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, {
      "tailwind.config.js", "tailwind.config.cjs", "tailwind.config.mjs", "tailwind.config.ts",
      "postcss.config.js", "postcss.config.cjs", "postcss.config.mjs", "postcss.config.ts",
    })
    if root then on_dir(root) end
  end,
  settings = {
    tailwindCSS = {
      validate = true,
      classAttributes = { "class", "className", "class:list", "classList", "ngClass" },
    },
  },
}
