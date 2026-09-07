-- Python types and navigation. ruff (separate server) does lint and format.
-- Plain pyright, not basedpyright: projects pin pyright in their dev deps and
-- pre-commit, and configure it via pyrightconfig.json / [tool.pyright]. Same
-- server here means nvim shows what CI shows.
--
-- typeCheckingMode "off" is the default: hover, goto-definition, references
-- and rename everywhere, diagnostics nowhere. A project that actually uses
-- pyright sets the mode in its own config file, which overrides this. A
-- mypy-only project gets no pyright opinions.
return {
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = { "pyrightconfig.json", "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,       -- finds src/ layouts
        diagnosticMode = "openFilesOnly",
        typeCheckingMode = "off",
      },
    },
  },
  -- Pyright does not look for a venv on its own; without this it resolves
  -- imports against whatever python3 is on PATH, i.e. the global uv one, and
  -- every third-party import in the project shows as unresolved. Point it at
  -- <root>/.venv when there is one. A pyrightconfig.json venv/venvPath, if
  -- present, still overrides this.
  before_init = function(_, config)
    local venv_python = (config.root_dir or "") .. "/.venv/bin/python"
    if config.root_dir and vim.uv.fs_stat(venv_python) then
      config.settings.python.pythonPath = venv_python
    end
  end,
}
