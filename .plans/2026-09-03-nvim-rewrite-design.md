# Neovim config rewrite: from LazyVim to a hand-written config

## Goal

Own every line. Drop the LazyVim dependency. Learn how a config is built by
writing it in a pair session: Kalvis types, Claude explains and reviews.
Target is parity: everything used today keeps working before the switch.

## Decisions

- **Neovim 0.12** built-ins first. A plugin is added only when the built-in is
  missing or clearly worse.
- **Plugin manager: `vim.pack`** (built in). `vim.pack.add()` in `init.lua`,
  lockfile `nvim-pack-lock.json` committed. No lazy-loading framework; where
  deferred loading matters it is written by hand with autocmds.
- **LSP: native** `vim.lsp.config` / `vim.lsp.enable` with one `lsp/<server>.lua`
  per server. nvim-lspconfig's repo is reference material only.
- **Tools: mason.nvim** installs language servers, formatters, linters and the
  tree-sitter CLI (decided 2026-09-03, revising the earlier "system packages"
  choice). Principle: the config must work on any machine right after
  cloning. Mason is a downloader only: no mason-lspconfig, no auto-wiring;
  a plain list of package names, missing ones installed on startup. The
  bootstrap script is reduced to runtimes Mason needs: nvim, git, a C
  compiler, node, python3, go, ripgrep.
- **Parallel install** while building: `~/.config/nvim-next`, launched with
  `NVIM_APPNAME=nvim-next nvim`. Separate data/state/cache. Old config stays
  untouched until the swap. Moves under `dotfiles/` when it becomes daily driver.
- **Layout**: modular. `init.lua` requires `config.options`, `config.keymaps`,
  `config.autocmds`, `config.plugins`; plugins configured in `lua/plugins/*.lua`,
  one file per plugin or topic, each a plain module (no spec tables to merge).
- Commits: one line, conventional prefix, no co-author.

## Build order

Each step ends in a usable editor.

1. `init.lua`, options. Parity reference: LazyVim `config/options.lua` plus ours.
2. Keymaps, autocmds. Port `lua/config/keymaps.lua` and `autocmds.lua`.
3. `vim.pack` bootstrap and colorscheme (cyberdream).
4. Treesitter: parsers, highlight, indent.
5. LSP: `lsp/*.lua` for gopls, basedpyright/pyright, ruff, rust-analyzer, vtsls,
   yaml, json, marksman, tailwind; `LspAttach` keymaps; diagnostics config.
6. Completion and snippets.
7. Picker (files, grep, buffers, symbols, diagnostics).
8. Git: gitsigns, diffview (file carried over), gitlineage.
9. Formatting (conform) and linting (nvim-lint).
10. Editing: flash, yanky, multicursor, mini.ai, mini.pairs, ts-autotag, oil,
    grug-far, trouble, inc-rename.
11. UI: statusline, bufferline, noice, dashboard, indent guides, todo, smear.

## Not carried over unless missed

which-key, catppuccin, tokyonight, snacks explorer, snacks scroll, lazygit,
grug-far (never used), render-markdown (not wanted), mini.diff (gitsigns
instead), illuminate and mini.indentscope (snacks words/indent instead).

## Progress (2026-09-04)

Steps 1-11 written in `~/.config/nvim-next` and verified headless. 31 plugins
under `vim.pack`, 31 Mason packages, 20 `lsp/*.lua`. Remaining: daily use,
then the swap (delete `~/.local/share/nvim` and `~/.local/state/nvim`, rename
`nvim-next` to `nvim`, move under `dotfiles/`).

## Verification

Per step: launch `NVIM_APPNAME=nvim-next nvim`, exercise the feature, `:checkhealth`
where applicable. Before the swap: a day of real use on the new config.
