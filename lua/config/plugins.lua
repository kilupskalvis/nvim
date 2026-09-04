-- Every plugin, one place. vim.pack.add clones missing ones into
-- ~/.local/share/nvim-next/site/pack/core/opt/ (asks once), then adds all
-- of them to the runtime path. Exact revisions are recorded in
-- nvim-pack-lock.json next to init.lua; commit that file.
--
-- Update everything: :lua vim.pack.update()   (shows a diff, confirm to apply)
-- Remove one:        :lua vim.pack.del({ "name" })
vim.pack.add({
  { src = "https://github.com/scottmckendry/cyberdream.nvim" },
  { src = "https://github.com/mason-org/mason.nvim" },
  -- main branch: the rewrite with install()/get_installed(); master is frozen.
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  -- JSON/YAML schema catalog, read by the jsonls and yamlls definitions
  { src = "https://github.com/b0o/SchemaStore.nvim" },
  -- teaches lua-language-server the `vim` API for this config
  { src = "https://github.com/folke/lazydev.nvim" },
  -- completion; pinned to releases so the prebuilt fuzzy-matcher binary matches
  { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("1.*") },
  -- picker, bigfile, notifier, terminal, git helpers (modules opt-in)
  { src = "https://github.com/folke/snacks.nvim" },
  -- git
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
  { src = "https://github.com/sindrets/diffview.nvim" },
  { src = "https://github.com/lionyxml/gitlineage.nvim" }, -- needs diffview
  -- formatting and linting
  { src = "https://github.com/stevearc/conform.nvim" },
  { src = "https://github.com/mfussenegger/nvim-lint" },
  -- editing
  { src = "https://github.com/folke/flash.nvim" },
  { src = "https://github.com/gbprod/yanky.nvim" },
  { src = "https://github.com/jake-stewart/multicursor.nvim" },
  { src = "https://github.com/nvim-mini/mini.ai" },
  { src = "https://github.com/nvim-mini/mini.pairs" },
  { src = "https://github.com/windwp/nvim-ts-autotag" },
  { src = "https://github.com/folke/trouble.nvim" },
  { src = "https://github.com/smjonas/inc-rename.nvim" },
  { src = "https://github.com/stevearc/oil.nvim" },
  { src = "https://github.com/nvim-tree/nvim-web-devicons" }, -- some plugins require it by name
  { src = "https://github.com/nvim-mini/mini.icons" },         -- the icons actually shown; mocks devicons
  -- ui
  { src = "https://github.com/nvim-lualine/lualine.nvim" },
  { src = "https://github.com/akinsho/bufferline.nvim" },
  { src = "https://github.com/MunifTanjim/nui.nvim" }, -- noice dependency
  { src = "https://github.com/folke/noice.nvim" },
  { src = "https://github.com/folke/todo-comments.nvim" },
  { src = "https://github.com/nvim-mini/mini.hipatterns" },
  { src = "https://github.com/sphamba/smear-cursor.nvim" },
})

-- Per-plugin configuration. Each module calls the plugin's setup().
require("plugins.colorscheme")
require("plugins.icons") -- before anything that draws icons
require("plugins.mason") -- before treesitter: it needs tree-sitter-cli on PATH
require("plugins.treesitter")
require("plugins.completion") -- before lsp: sets client capabilities for every server
require("plugins.lsp")
require("plugins.snacks")
require("plugins.gitsigns")
require("plugins.diffview")
require("plugins.gitlineage")
require("plugins.format")
require("plugins.lint")
require("plugins.editing")
require("plugins.oil")
require("plugins.ui")
