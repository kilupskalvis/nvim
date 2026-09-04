-- YAML with schema validation from SchemaStore: GitHub workflows,
-- docker-compose, k8s manifests. The server's own schema store is turned
-- off so the plugin's list is the single source.
return {
  cmd = { "yaml-language-server", "--stdio" },
  filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab", "yaml.helm-values" },
  root_markers = { ".git" },
  settings = {
    redhat = { telemetry = { enabled = false } },
    yaml = {
      format = { enable = true },
      keyOrdering = false,
      schemaStore = { enable = false, url = "" },
      schemas = require("schemastore").yaml.schemas(),
    },
  },
  on_init = function(client)
    client.server_capabilities.documentFormattingProvider = true
  end,
}
