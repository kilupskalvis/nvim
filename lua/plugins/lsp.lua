-- Native LSP wiring. Server definitions live in lsp/<name>.lua at the config
-- root; Neovim reads them by name when enabled below. Three concerns here:
-- which servers to enable, what happens when one attaches to a buffer, and
-- how diagnostics are displayed.

-- Servers -----------------------------------------------------------------

local servers = {
  "lua_ls", "gopls", "basedpyright", "ruff", "djls", "djlsp", "rust_analyzer",
  "vtsls", "eslint", "jsonls", "yamlls", "html", "cssls", "tailwindcss",
  "bashls", "dockerls", "docker_compose_language_service", "marksman", "taplo", "clangd",
}

-- Only enable servers whose binary exists. Mason has prepended its bin/ to
-- PATH by now (plugins.mason loads first). A missing server degrades to
-- "no LSP for that language" and a note in :checkhealth config, instead of
-- an error on every buffer of that filetype.
local missing = {}
for _, name in ipairs(servers) do
  local cfg = vim.lsp.config[name]
  local bin = cfg and type(cfg.cmd) == "table" and cfg.cmd[1]
  if bin and vim.fn.executable(bin) == 0 then
    table.insert(missing, ("%s (%s)"):format(name, bin))
  else
    vim.lsp.enable(name)
  end
end

vim.health = vim.health or {}
-- :checkhealth config
package.preload["config.health"] = function()
  return {
    check = function()
      vim.health.start("LSP servers")
      if #missing == 0 then
        vim.health.ok("all configured servers found on PATH")
      else
        for _, m in ipairs(missing) do vim.health.warn("not found: " .. m, "install with :Mason") end
      end
    end,
  }
end

-- Attach ------------------------------------------------------------------
-- Runs once per (server, buffer). Neovim already provides defaults:
-- grn rename, gra code action, grr references, gri implementation,
-- grt type definition, gO document symbols, <C-s> signature help (insert).
-- We add the <leader>c family and a few gd-style keys.
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("config_lsp_attach", { clear = true }),
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    local buf = args.buf
    local function map(lhs, rhs, desc, mode)
      vim.keymap.set(mode or "n", lhs, rhs, { buffer = buf, desc = desc })
    end

    map("gd", vim.lsp.buf.definition, "Go to definition")
    map("gD", vim.lsp.buf.declaration, "Go to declaration")
    map("gI", vim.lsp.buf.implementation, "Go to implementation")
    map("gy", vim.lsp.buf.type_definition, "Go to type definition")
    map("gr", vim.lsp.buf.references, "References")
    -- inc-rename previews every occurrence while you type the new name.
    -- expr mapping: returns the command line to run, cursor word prefilled.
    if package.loaded["inc_rename"] then
      vim.keymap.set("n", "<leader>cr", function()
        return ":IncRename " .. vim.fn.expand("<cword>")
      end, { buffer = buf, expr = true, desc = "Rename (preview)" })
    else
      map("<leader>cr", vim.lsp.buf.rename, "Rename")
    end
    map("<leader>ca", vim.lsp.buf.code_action, "Code action", { "n", "x" })
    -- gK, not <leader>cs (Trouble symbols) and not insert <C-s> (save).
    map("gK", vim.lsp.buf.signature_help, "Signature help")
    map("<leader>cl", "<cmd>checkhealth vim.lsp<cr>", "LSP info")
    map("<leader>cR", function()
      -- Restart every client attached to this buffer.
      for _, c in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
        vim.lsp.enable(c.name, false)
        vim.lsp.enable(c.name, true)
      end
    end, "Restart LSP")

    if client:supports_method("textDocument/inlayHint") then
      map("<leader>uh", function()
        local on = vim.lsp.inlay_hint.is_enabled({ bufnr = buf })
        vim.lsp.inlay_hint.enable(not on, { bufnr = buf })
      end, "Toggle inlay hints")
    end

    if client:supports_method("textDocument/codeLens") then
      map("<leader>cc", vim.lsp.codelens.run, "Run code lens")
    end

    -- ruff and basedpyright both attach to Python. basedpyright owns hover;
    -- otherwise you get two hover windows.
    if client.name == "ruff" then
      client.server_capabilities.hoverProvider = false
    end
  end,
})

-- Diagnostics --------------------------------------------------------------
vim.diagnostic.config({
  underline = true,
  update_in_insert = false,      -- wait until leaving insert mode
  severity_sort = true,          -- errors above warnings in signs and lists
  virtual_text = {
    spacing = 4,
    source = "if_many",          -- show which server when more than one reports
    prefix = "●",
  },
  float = { border = "rounded", source = "if_many" },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.HINT] = " ",
      [vim.diagnostic.severity.INFO] = " ",
    },
  },
})

-- lazydev: when editing this config, lua_ls gets Neovim's runtime files and
-- the plugin directory as library, so vim.* and plugin APIs resolve.
require("lazydev").setup({
  library = {
    { path = "${3rd}/luv/library", words = { "vim%.uv" } },
  },
})
