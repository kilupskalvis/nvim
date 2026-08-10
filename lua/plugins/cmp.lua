return {
  {
    "garymjr/nvim-snippets",
    enabled = false,
  },
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local cmp = require("cmp")
      opts.mapping = opts.mapping or {}
      opts.mapping["<CR>"] = LazyVim.cmp.confirm({
        select = true,
        behavior = cmp.ConfirmBehavior.Replace,
      })
      -- hjkl-shaped selection for the completion menu. It has to be C-j / C-k
      -- rather than bare j / k: the menu is open in insert mode, where those
      -- letters are literal text, and cmp pops up on almost every keystroke --
      -- binding them would make any word containing a j or k untypeable.
      -- <Down>/<Up> and <C-n>/<C-p> from LazyVim's preset still work.
      opts.mapping["<C-j>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert })
      opts.mapping["<C-k>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert })

      -- Tab walks the menu, Enter accepts. Tab used to accept as well, which
      -- left no way to step past the first suggestion without reaching for a
      -- different key. select_next_item wraps at the end of the list, so Tab
      -- alone is enough to reach every entry; C-k above goes back a step.
      --
      -- Snippet jumping stays on Tab for when no menu is open, which is the
      -- only time it could have fired anyway.
      opts.mapping["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
        elseif vim.snippet.active({ direction = 1 }) then
          vim.snippet.jump(1)
        else
          fallback()
        end
      end, { "i", "s" })
    end,
  },
}
