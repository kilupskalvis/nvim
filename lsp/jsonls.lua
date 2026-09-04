-- JSON with schema validation. Schemas come from SchemaStore (plugin) so
-- package.json, tsconfig.json, .eslintrc and hundreds more get completion.
return {
  cmd = { "vscode-json-language-server", "--stdio" },
  filetypes = { "json", "jsonc" },
  root_markers = { ".git" },
  init_options = { provideFormatter = true },
  settings = {
    json = {
      schemas = require("schemastore").json.schemas(),
      validate = { enable = true },
    },
  },
}
