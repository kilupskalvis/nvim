-- nvim-lint: runs linters that are not language servers and turns their
-- output into diagnostics. Python (ruff), JS/TS (eslint), Lua (lua_ls) are
-- already covered by servers, so only the stragglers are here.
-- Markdown linting deliberately off, as in the old config.
local lint = require("lint")

lint.linters_by_ft = {
  go = { "golangcilint" },
  dockerfile = { "hadolint" },
  htmldjango = { "djlint" },
}

-- Run on read, after write, and when leaving insert mode. Debounced so a
-- burst of saves triggers one run.
local timer = assert(vim.uv.new_timer())
local function try_lint()
  timer:stop()
  timer:start(100, 0, vim.schedule_wrap(function()
    local names = lint._resolve_linter_by_ft(vim.bo.filetype)
    -- only run linters whose binary exists; a missing one would error every save
    names = vim.tbl_filter(function(name)
      local l = lint.linters[name]
      return l and vim.fn.executable(type(l) == "function" and l().cmd or l.cmd) == 1
    end, names)
    if #names > 0 then lint.try_lint(names) end
  end))
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
  group = vim.api.nvim_create_augroup("config_lint", { clear = true }),
  callback = try_lint,
})
