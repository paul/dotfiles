local o = vim.o
local g = vim.g
local cmd = vim.cmd
local env = vim.env

require('plugins')

-- Options


o.autoread = true                   -- automatically reload files if they change on disk
o.autowriteall = true               -- Save files when switching buffers

o.wrap = true                       -- wrap lines
o.linebreak = true                  -- wrap at whole words
o.showbreak = '⏎'

o.expandtab = true
o.softtabstop = 2
o.tabstop = 2
o.shiftwidth = 2
o.backspace = 'indent,eol,start' -- allow backspacing over everything in insert mode
o.autoindent = true                 -- always set autoindenting on
o.number = true                     -- always show line numbers
o.shiftround = true                 -- use multiple of shiftwidth when indenting with '<' and '>'
o.showmatch = true                  -- set show matching parenthesis

o.swapfile = false
o.backup = false

o.hlsearch = true         -- highlight search terms
o.incsearch = true        -- show search matches as you type
o.smartcase = true        -- ignore case if search pattern is all lowercase, case-sensitive otherwise
o.smarttab = true         -- insert tabs on the start of a line according to shiftwidth, not tabstop

o.list = true             -- show invisible characters
o.listchars = 'tab:│·,trail:·,extends:#,nbsp:·'

o.title = true                      -- change the terminal's title
o.showcmd = true                    -- show (partial) command in the last line of the screen
o.modeline = true                   -- allow files to include a 'mode line', to override vim defaults
o.modelines = 5                -- check the first 5 lines for a modeline

o.mouse = 'a'

-- Maintain undo history between sessions
o.undofile = true
o.undolevels = 1000
o.undoreload = 10000

-- Try to show more context when scrolling
o.scrolloff = 5
o.sidescrolloff = 10

o.splitbelow = true
o.splitright = true

-- There are not word dividers
o.iskeyword = o.iskeyword .. '$' .. '_'

-- let mapleader="\<Space>"
g.mapleader = [[ ]]

-- yank/put use the OS clipboard
o.clipboard = o.clipboard .. 'unnamedplus'

--
-- Commands
--
local map_key = vim.api.nvim_set_keymap

local function map(modes, lhs, rhs, opts)
  opts = opts or {}
  opts.noremap = opts.noremap == nil and true or opts.noremap
  if type(modes) == 'string' then modes = {modes} end
  for _, mode in ipairs(modes) do map_key(mode, lhs, rhs, opts) end
end

-- Reload this config
-- not sure how to reference init.lua file, $MYVIMRC isn't a thing
--nmap <leader>r :so $MYVIMRC<CR>
--map_key('n', '<leader>r', '<cmd>so $MYVIMRC<cr>', {})

-- Write file on <Enter>
map_key('n', '<CR>', ':write!<CR>', {})

-- Easy window navigation
map_key('n', '<C-h>', '<C-w>h', {})
map_key('n', '<C-j>', '<C-w>j', {})
map_key('n', '<C-k>', '<C-w>k', {})
map_key('n', '<C-l>', '<C-w>l', {})
map_key('n', '<C-tab>', '<C-w>p', {})

map_key('n', '<leader>[', ':bp<cr>', {})
map_key('n', '<leader>]', ':bn<cr>', {})

--
-- Plugins
--

-- LSP

-- local function setup_servers()
--   require'lspinstall'.setup()
--   local servers = require'lspinstall'.installed_servers()
--   for _, server in pairs(servers) do
--     require'lspconfig'[server].setup{}
--   end
-- end
-- 
-- setup_servers()
-- 
-- -- Automatically reload after `:LspInstall <server>` so we don't have to restart neovim
-- require'lspinstall'.post_install_hook = function ()
--   setup_servers() -- reload installed servers
--   vim.cmd("bufdo e") -- this triggers the FileType autocmd that starts the server
-- end

-- Hide inline error display (using ALE for that)
vim.lsp.handlers["textDocument/publishDiagnostics"] = function() end
require'lspconfig'.solargraph.setup{}

-- ALE

map_key('n', '<C-k>', '<Plug>(ale_previous_wrap)', { silent = true })
map_key('n', '<C-j>', '<Plug>(ale_next_wrap)', { silent = true })


g.ale_sign_column_always = 1
g.ale_sign_error = 'ﱥ'
g.ale_sign_warning = ''

g.ale_set_highlights = 1
g.ale_lint_delay = 500

-- cnoreabbrev Fix ALEFix
g.ale_fix_on_save = 1
g.ale_fixers = {
  reason =     {'refmt'},
  ruby =       {'rubocop'},
  rust =       {'rustfmt'},
  go =         {'gofmt'},
  elm =        {'elm-format'},
  javascript = {'prettier', 'eslint'},
}

-- Lets ALE/Rubocop add frozen_string_literal comments
g.ale_ruby_rubocop_auto_correct_all = 1


-- highlight ALEErrorSign ctermbg=18 ctermfg=09
-- highlight ALEWarningSign ctermbg=18 ctermfg=03

-- Bufferline
require('bufferline').setup{
  options = {
    show_buffer_close_icons = false,
    show_close_icon = false,
    separator_style = "slant",
    numbers = "ordinal",
    number_style = "superscript",
    mappings = true  -- <leader>-# to go to tab

  }
}

-- compe

o.completeopt = "menuone,noselect"
require'compe'.setup({
  enabled = true,
  autocomplete = false, -- don't open menu automatically
  source = {
    path = { priority = 20 },
    buffer = { priority = 1 },
    nvim_lsp = { priority = 10 },
  },
})
-- vim.cmd[[inoremap <silent><expr> <C-Space> compe#complete()]]
-- vim.cmd[[inoremap <silent><expr> <CR>      compe#confirm(lexima#expand('<LT>CR>', 'i'))]]
-- vim.cmd[[inoremap <silent><expr> <C-e>     compe#close('<C-e>')]]
-- vim.cmd[[inoremap <silent><expr> <C-f>     compe#scroll({ 'delta': +4 })]]
-- vim.cmd[[inoremap <silent><expr> <C-d>     compe#scroll({ 'delta': -4 })]]

local t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local check_back_space = function()
    local col = vim.fn.col('.') - 1
    if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
        return true
    else
        return false
    end
end

-- Use (s-)tab to:
--- move to prev/next item in completion menuone
--- jump to prev/next snippet's placeholder
_G.tab_complete = function()
  if vim.fn.pumvisible() == 1 then
    return t "<C-n>"
  -- elseif vim.fn.call("vsnip#available", {1}) == 1 then
  --   return t "<Plug>(vsnip-expand-or-jump)"
  elseif check_back_space() then
    return t "<Tab>"
  else
    return vim.fn['compe#complete']()
  end
end
_G.s_tab_complete = function()
  if vim.fn.pumvisible() == 1 then
    return t "<C-p>"
  -- elseif vim.fn.call("vsnip#jumpable", {-1}) == 1 then
  --   return t "<Plug>(vsnip-jump-prev)"
  else
    return t "<S-Tab>"
  end
end

vim.api.nvim_set_keymap("i", "<Tab>", "v:lua.tab_complete()", {expr = true})
vim.api.nvim_set_keymap("s", "<Tab>", "v:lua.tab_complete()", {expr = true})
vim.api.nvim_set_keymap("i", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
vim.api.nvim_set_keymap("s", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})


-- gitsigns
require('gitsigns').setup()


-- lualine
require('lualine').setup {
  options = {
    theme = 'tokyonight'
  }
}

-- telescope
map_key('n', '<C-Space>', '<cmd>Telescope find_files<cr>',  { noremap = true })

-- vim-ruby

g.ruby_indent_assignment_style = 'variable'
g.ruby_indent_block_style = 'do'

-- easyalign
-- Start interactive EasyAlign in visual mode
map_key('v', '<Enter>', '<Plug>(EasyAlign)', {})

-- Start interactive EasyAlign with a Vim movement
map_key('n', '<Leader>a', '<Plug>(EasyAlign)', {})

-- vim-json
-- Disable quote concealing
g.vim_json_syntax_conceal = 0

-- Theme
vim.g.tokyonight_style = "night"
vim.cmd[[colorscheme tokyonight]]

-- Todo is black on yellow bg, and looks terrible for ALEWarningSign
-- Todo ctermfg=0 ctermbg=11 guifg=#1a1b26 guibg=#e0af68
local colors = require("tokyonight.colors").setup(require("tokyonight.config"))
local util = require("tokyonight.util")

-- vim.cmd[[highlight! link ALEWarningSign NONE]]
-- util.highlight("ALEWarningSign", { fg = colors.warning })
-- the above doesn't work, because tokyonight clears all highlight groups on load
vim.cmd[[augroup custom_highlight ]]
vim.cmd[[  autocmd!]]
vim.cmd([[  au ColorScheme * highlight AleWarningSign ctermfg=3 ctermbg=NONE guifg=]] .. colors.warning .. [[ guibg=NONE]])
vim.cmd[[augroup end]]

