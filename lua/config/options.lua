-- Leader keys. Read when a keymap is defined, so these come before anything that creates keymaps. Literal strings: " " is Space, not "<Space>".
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local o = vim.opt

-- Display ---------------------------------------------------------------
o.number = true          -- absolute number on the current line
o.relativenumber = true  -- distances on the others, so 5j is readable off the gutter
o.cursorline = true      -- highlight the line the cursor is on
o.signcolumn = "yes"     -- always reserve the gutter for git/diagnostic signs, no text jumping
o.termguicolors = true   -- 24-bit colors; every modern colorscheme assumes this
o.scrolloff = 8          -- keep 8 lines visible above/below the cursor while scrolling
o.sidescrolloff = 8      -- same horizontally when wrap is off
o.wrap = false           -- long lines run off screen instead of wrapping
o.linebreak = true       -- if wrap is turned on later, break at words not mid-word
o.list = true            -- render invisible characters per listchars below
o.listchars = { tab = "» ", trail = "·", nbsp = "␣" } -- tabs, trailing spaces, non-breaking spaces
o.fillchars = { eob = " " } -- no ~ column after the last line
o.showmode = false       -- statusline will show the mode; drop the -- INSERT -- echo
o.laststatus = 3         -- one statusline for the whole editor instead of one per window
o.pumheight = 10         -- completion popup shows at most 10 rows
o.pumblend = 10          -- slight transparency on that popup
o.conceallevel = 2       -- hide markup like ** in markdown while showing the text
o.smoothscroll = true    -- Ctrl-e/y scroll by screen line on wrapped text

-- Indentation -----------------------------------------------------------
o.tabstop = 4            -- a tab character displays as 4 columns
o.shiftwidth = 4         -- >> and autoindent move by 4
o.softtabstop = 4        -- Tab/Backspace in insert mode act on 4 columns
o.expandtab = true       -- Tab inserts spaces, never a tab character
o.smartindent = true     -- new line copies indent and adds one after { and keywords
o.shiftround = true      -- >> rounds to a multiple of shiftwidth

-- Search ----------------------------------------------------------------
o.ignorecase = true      -- /foo matches Foo
o.smartcase = true       -- ...unless the pattern has a capital, then exact case
o.inccommand = "nosplit" -- :s/a/b shows the replacement live in the buffer
o.grepprg = "rg --vimgrep"   -- :grep uses ripgrep
o.grepformat = "%f:%l:%c:%m" -- and knows how to parse its output

-- Windows and splits ----------------------------------------------------
o.splitright = true      -- :vsplit opens to the right
o.splitbelow = true      -- :split opens below
o.splitkeep = "screen"   -- text stays put on screen when a split opens or closes
o.winminwidth = 5        -- a squeezed window keeps at least 5 columns

-- Editing behavior ------------------------------------------------------
o.undofile = true        -- undo history survives closing the file
o.undolevels = 10000     -- and keeps a lot of it
o.autowrite = true       -- write before commands like :make or buffer switch that would lose edits
o.confirm = true         -- ask to save instead of failing when quitting a modified buffer
o.virtualedit = "block"  -- in visual block mode the cursor may sit past line end
o.formatoptions = "jcroqlnt" -- how auto-formatting behaves: j joins comments sanely,
                             -- c/r/o continue comments, q allows gq, l keeps long lines,
                             -- n recognizes numbered lists, t wraps text at textwidth
o.completeopt = "menu,menuone,noselect" -- completion menu: show it, even for one item, don't preselect
o.jumpoptions = "view"   -- jumping back restores the scroll position too
o.mouse = "a"            -- mouse works in all modes
o.spelllang = { "en" }   -- language for :set spell when you turn it on
o.wildmode = "longest:full,full" -- command-line Tab completes the longest common part, then cycles

-- Timing ----------------------------------------------------------------
o.updatetime = 200       -- ms of idle before CursorHold fires and swap is written
o.timeoutlen = 300       -- ms to wait for the next key in a multi-key mapping

-- Clipboard -------------------------------------------------------------
-- Yank and paste go through the system clipboard. Over SSH there is no local
-- clipboard, so use the OSC 52 terminal escape: the terminal on your machine
-- does the copy. Paste reads the unnamed register since terminals cannot
-- report their clipboard back.
o.clipboard = "unnamedplus"
if vim.env.SSH_CONNECTION then
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = function() return { vim.fn.getreg(""), vim.fn.getregtype("") } end,
      ["*"] = function() return { vim.fn.getreg(""), vim.fn.getregtype("") } end,
    },
  }
end

-- Messages --------------------------------------------------------------
-- Silence: W file written, I intro screen, c/C completion-menu chatter.
o.shortmess:append({ W = true, I = true, c = true, C = true })

-- Sessions --------------------------------------------------------------
-- What :mksession records. Needed later if we add session restore.
o.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
