-- Python types and navigation. ruff (separate server) does lint and format.
return {
  cmd = { "basedpyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = { "pyrightconfig.json", "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
  settings = {
    basedpyright = {
      analysis = {
        autoSearchPaths = true,       -- finds src/ layouts and the active venv
        diagnosticMode = "openFilesOnly",
      },
      disableTaggedHints = true,      -- no greyed-out "unreachable" hints
    },
  },
}
