-- Attaches only to buffers whose filetype is yaml.docker-compose, which
-- Neovim sets for compose file names automatically.
return {
  cmd = { "docker-compose-langserver", "--stdio" },
  filetypes = { "yaml.docker-compose" },
  root_markers = { "docker-compose.yaml", "docker-compose.yml", "compose.yaml", "compose.yml" },
}
