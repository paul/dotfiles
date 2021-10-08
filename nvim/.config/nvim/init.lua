local o = vim.opt
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
o.backspace = 'indent,eol,start'    -- allow backspacing over everything in insert mode
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
o.iskeyword:append('$')
o.iskeyword:append('_')


-- let mapleader="\<Space>"
g.mapleader = [[ ]]

-- yank/put use the OS clipboard
--o.clipboard = o.clipboard .. 'unnamedplus'
--o.clipboard:append('unnamedplus')
-- table.insert(o.clipboard, 'unnamedplus')
o.clipboard = 'unnamedplus'

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

-- Using barbar instead
-- next/previous buffer
-- map_key('n', '<leader>[', ':bp<cr>', {})
-- map_key('n', '<leader>]', ':bn<cr>', {})

-- last used buffer
-- map_key('n', '<leader>`', ':b#<cr>', {})

--
-- Plugins
--

-- cmp

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

local cmp = require'cmp'
cmp.setup({
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  mapping = {
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    }),
    ['<Tab>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'i', 's' })
  },
  formatting = {
    format = function(entry, vim_item)
    vim_item.menu = ({
      buffer = "[Buffer]",
      nvim_lsp = "[LSP]",
      luasnip = "[LuaSnip]",
      nvim_lua = "[Lua]",
      latex_symbols = "[Latex]",
    })[entry.source.name]
    return vim_item
    end,
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'buffer' },
  }
})

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

-- Ruby
require'lspconfig'.solargraph.setup{
  cmd = { "bundle", "exec", "solargraph", "stdio" }
}

-- Go 
require'lspconfig'.gopls.setup{}

-- Rust
require'lspconfig'.rust_analyzer.setup{}
local opts = {
  tools = { -- rust-tools options
    autoSetHints = true,
    hover_with_actions = true,
    inlay_hints = {
      show_parameter_hints = false,
      parameter_hints_prefix = "",
      other_hints_prefix = "",
    },
  },

  -- all the opts to send to nvim-lspconfig
  -- these override the defaults set by rust-tools.nvim
  -- see https://github.com/neovim/nvim-lspconfig/blob/master/CONFIG.md#rust_analyzer
  server = {
    -- on_attach is a callback called when the language server attachs to the buffer
    -- on_attach = on_attach,
    settings = {
      -- to enable rust-analyzer settings visit:
      -- https://github.com/rust-analyzer/rust-analyzer/blob/master/docs/user/generated_config.adoc
      ["rust-analyzer"] = {
        -- enable clippy on save
        checkOnSave = {
          command = "clippy"
        },
      }
    }
  },
}

require('rust-tools').setup(opts)

local nvim_lsp = require('lspconfig')
-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  --Enable completion triggered by <c-x><c-o>
  -- -- using cmp instead for completion --
  -- buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local opts = { noremap=true, silent=true }

  buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
  buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
end

-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
local servers = { "solargraph", "rust_analyzer" }
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup {
    on_attach = on_attach,
    flags = {
      debounce_text_changes = 150,
    },
    capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities()),
  }
end

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


-- Fixes ALE gutter colors on some themes
-- highlight ALEErrorSign ctermbg=18 ctermfg=09
-- highlight ALEWarningSign ctermbg=18 ctermfg=03

-- Barbar
map_key('n', '<leader>[', ':BufferPrevious<CR>', { silent = true })
map_key('n', '<leader>]', ':BufferNext<CR>', { silent = true })
map_key('n', '<leader>{', ':BufferMovePrevious<CR>', { silent = true })
map_key('n', '<leader>}', ':BufferMoveNext<CR>', { silent = true })

map_key('n', '<leader>1', ':BufferGoto 1<CR>', { silent = true })
map_key('n', '<leader>2', ':BufferGoto 2<CR>', { silent = true })
map_key('n', '<leader>3', ':BufferGoto 3<CR>', { silent = true })
map_key('n', '<leader>4', ':BufferGoto 4<CR>', { silent = true })
map_key('n', '<leader>5', ':BufferGoto 5<CR>', { silent = true })
map_key('n', '<leader>6', ':BufferGoto 6<CR>', { silent = true })
map_key('n', '<leader>7', ':BufferGoto 7<CR>', { silent = true })
map_key('n', '<leader>8', ':BufferGoto 8<CR>', { silent = true })
map_key('n', '<leader>9', ':BufferGoto 9<CR>', { silent = true })

-- magic buffer closer without messing with window layout
map_key('n', '<leader>c', ':BufferClose<CR>', { silent = true })

-- pick buffer by stable key
map_key('n', '<leader>b', ':BufferPick<CR>', { silent = true })


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

--
-- Theme
--

--   tokyonight
g.tokyonight_style = "night"
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

