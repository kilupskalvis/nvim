-- Django language server: the Python side (models, urls, settings).
-- Only useful inside a Django project, so manage.py is the first marker.
return {
  cmd = { "djls", "serve" },
  filetypes = { "htmldjango", "html", "python" },
  root_markers = { "manage.py", "pyproject.toml", ".git" },
}
