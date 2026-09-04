-- Django templates: tags, filters, template and static paths.
-- Django projects only: manage.py is the root marker and it is required.
return {
  cmd = { "djlsp" },
  filetypes = { "html", "htmldjango" },
  root_markers = { "manage.py" },
  workspace_required = true,
}
