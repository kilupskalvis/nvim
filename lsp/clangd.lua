-- C and C++. Wants compile_commands.json (from CMake or bear) to know
-- include paths; without it, falls back to heuristics for the open file.
return {
  cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu", "--completion-style=detailed" },
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
  root_markers = { ".clangd", ".clang-tidy", ".clang-format", "compile_commands.json", "compile_flags.txt", "configure.ac", ".git" },
  capabilities = {
    textDocument = { completion = { editsNearCursor = true } },
    offsetEncoding = { "utf-8", "utf-16" },
  },
  on_init = function(client, init_result)
    if init_result.offsetEncoding then client.offset_encoding = init_result.offsetEncoding end
  end,
  on_attach = function(client, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, "LspClangdSwitchSourceHeader", function()
      client:request("textDocument/switchSourceHeader", vim.lsp.util.make_text_document_params(bufnr), function(err, result)
        if err then error(tostring(err)) end
        if result then vim.cmd.edit(vim.uri_to_fname(result)) else vim.notify("no corresponding file") end
      end, bufnr)
    end, { desc = "Switch between source and header" })
  end,
}
