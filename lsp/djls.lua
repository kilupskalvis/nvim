-- Django language server: the Python side (models, urls, settings).
-- Only inside a Django project: the sole root marker is manage.py, and
-- workspace_required means no root, no server, so plain Python projects
-- never see it.
return {
  cmd = { "djls", "serve" },
  filetypes = { "htmldjango", "html", "python" },
  root_markers = { "manage.py" },
  workspace_required = true,
}
