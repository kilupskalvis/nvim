-- Neovim ships the treesitter engine (vim.treesitter) and a handful of
-- parsers. nvim-treesitter (main branch) adds two things: an installer that
-- downloads and compiles parsers, and the query files that map tree nodes to
-- highlight groups, indent rules and folds for each language.
--
-- It has no setup({ ensure_installed }) any more. You ask it to install
-- parsers, and you turn features on per buffer yourself.
local ts = require("nvim-treesitter")

local parsers = {
  -- shipped with Neovim, listed so the set is explicit
  "lua", "vim", "vimdoc", "query", "c", "markdown", "markdown_inline",
  -- languages from the old LazyVim extras
  "go", "gomod", "gosum", "gowork",
  "cpp", -- c is bundled with Neovim
  "python",
  "rust",
  "typescript", "tsx", "javascript", "jsdoc",
  "json", "yaml", "toml", -- jsonc reuses the json parser
  "dockerfile",
  "html", "css",
  "bash", "regex",
  "gitcommit", "gitignore", "diff", "git_rebase",
  "sql",
}

-- Install what is missing. Async: parsers compile in the background with cc
-- and highlighting lights up as each one lands. Nothing to do on later starts.
local installed = ts.get_installed()
local missing = vim.tbl_filter(function(p) return not vim.tbl_contains(installed, p) end, parsers)
if #missing > 0 then
  ts.install(missing)
end

-- Per buffer: when the filetype is known and a parser for it exists, start
-- highlighting and switch folding and indentation to the tree.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("config_treesitter", { clear = true }),
  callback = function(args)
    -- start() errors when no parser is available for this filetype; that is
    -- the normal case for plain text, so swallow it.
    if not pcall(vim.treesitter.start, args.buf) then return end

    -- vim.wo[0][0] sets the option for this window *and* this buffer only,
    -- so a later buffer in the same window gets its own value.
    vim.wo[0][0].foldmethod = "expr"
    vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.wo[0][0].foldlevel = 99 -- open everything; zc/zM fold by hand

    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
