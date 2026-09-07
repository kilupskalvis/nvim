-- Python types and navigation. ruff (separate server) does lint and format.
-- Plain pyright, not basedpyright: projects pin pyright in their dev deps and
-- pre-commit, and configure it via pyrightconfig.json / [tool.pyright]. Same
-- server here means nvim shows what CI shows.
return {
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = { "pyrightconfig.json", "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,       -- finds src/ layouts and the active venv
        diagnosticMode = "openFilesOnly",
      },
    },
  },
}
