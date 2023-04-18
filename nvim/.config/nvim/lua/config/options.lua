-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

-- Look for a .nvim.lua in folders
opt.exrc = true

-- Files
opt.autoread = true     -- automatically reload files if they change on disk
opt.autowriteall = true -- Save files when switching buffers

-- Line Wrapping
opt.wrap = true      -- wrap lines
opt.linebreak = true -- wrap at whole words
opt.showbreak = "⏎"

-- Tabs/Spaces
opt.expandtab = true               -- use spaces instead of tabs
opt.tabstop = 2                    -- number of spaces to use when replacing tabs
opt.softtabstop = 2
opt.shiftwidth = 2                 -- size of an indent
opt.backspace = "indent,eol,start" -- allow backspacing over everything in insert mode
opt.autoindent = true              -- always set autoindenting on
opt.shiftround = true              -- use multiple of shiftwidth when indenting with '<' and '>'
opt.showmatch = true               -- set show matching parenthesis

-- Line numbers
opt.number = true          -- always show line numbers
opt.relativenumber = false -- disable lazyvim's relative number

-- Backup files
opt.swapfile = false
opt.backup = false

-- Search
opt.hlsearch = true  -- highlight search terms
opt.incsearch = true -- show search matches as you type
opt.smartcase = true -- ignore case if search pattern is all lowercase, case-sensitive otherwise
opt.smarttab = true  -- insert tabs on the start of a line according to shiftwidth, not tabstop

-- Characters
opt.list = true -- show invisible characters
opt.listchars:append({ tab = "│·", trail = "·", extends = "#", nbsp = "·" })

-- Terminal
opt.title = true   -- change the terminal's title
opt.showcmd = true -- show (partial) command in the last line of the screen

-- Modeline
opt.modeline = true -- allow files to include a 'mode line', to override vim defaults
opt.modelines = 5   -- check the first 5 lines for a modeline

opt.mouse = "a"     -- enable mouse mode

-- Maintain undo history between sessions
opt.undofile = true
opt.undolevels = 1000
opt.undoreload = 10000

-- Try to show more context when scrolling
opt.scrolloff = 5
opt.sidescrolloff = 10

opt.splitbelow = true
opt.splitright = true

-- There are not word dividers
opt.iskeyword:append("$")
opt.iskeyword:append("_")

opt.conceallevel = 0
