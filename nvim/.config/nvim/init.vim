"
" Reload this config with <Space>-r
"

call plug#begin('~/.config/nvim/plugins')
" Do :PlugInstall after adding things to this list

Plug 'vimwiki/vimwiki'

Plug 'tpope/vim-sensible'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'vim-ruby/vim-ruby'
Plug 'tpope/vim-rails'
Plug 'tpope/vim-markdown'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-cucumber'

Plug 'ruanyl/vim-gh-line'          " <leader>gh to open line on github

Plug 'mileszs/ack.vim'             " :Ag search

Plug 'junegunn/fzf.vim'

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

Plug 'airblade/vim-gitgutter'
Plug 'mattn/webapi-vim'
Plug 'mattn/gist-vim'

Plug 'rhysd/devdocs.vim'

Plug 'w0rp/ale'
Plug 'neoclide/coc.nvim', {'do': { -> coc#util#install()}}

Plug 'tpope/vim-commentary'
Plug 'tpope/vim-eunuch' " Vim sugar for unix commands

Plug 'junegunn/vim-easy-align'

Plug 'rhysd/committia.vim'

" Trying out
Plug 'jeetsukumaran/vim-buffergator'
Plug 'ryanoasis/vim-devicons'

" Syntax plugins
Plug 'chriskempson/base16-vim'

Plug 'cespare/vim-toml'
Plug 'ekalinin/Dockerfile.vim'
Plug 'elixir-lang/vim-elixir'
Plug 'elmcast/elm-vim'
Plug 'elzr/vim-json'
Plug 'hashivim/vim-hashicorp-tools'
Plug 'jez/vim-github-hub'
Plug 'kchmck/vim-coffee-script'
Plug 'nathanielc/vim-tickscript'
Plug 'nginx/nginx', { 'rtp': 'contrib/vim' }
Plug 'othree/es.next.syntax.vim'
Plug 'othree/yajs.vim'
Plug 'reasonml-editor/vim-reason-plus'
Plug 'rust-lang/rust.vim'

call plug#end()


" Sensible is some nice defaults, but make sure we load it first
" so everything in this file overrides it
runtime! plugin/sensible.vim

syntax on

set background=dark
let base16colorspace=256
colorscheme base16-oceanicnext

" Add a ruler at 80 and 120 columns
set colorcolumn=80,120
hi ColorColumn ctermbg=234 guibg=#1D1E2C

set autoread                   " automatically reload files if they change on disk
set autowriteall               " Save files when switching buffers

set wrap                       " wrap lines
set expandtab
set softtabstop=2
set tabstop=2
set shiftwidth=2
set backspace=indent,eol,start " allow backspacing over everything in insert mode
set autoindent                 " always set autoindenting on
set number                     " always show line numbers
set shiftround                 " use multiple of shiftwidth when indenting with '<' and '>'
set showmatch                  " set show matching parenthesis

set noswapfile
set nobackup

set hlsearch         " highlight search terms
set incsearch        " show search matches as you type
set smartcase        " ignore case if search pattern is all lowercase, case-sensitive otherwise
set smarttab         " insert tabs on the start of a line according to shiftwidth, not tabstop

set list             " show invisible characters
set listchars=tab:│·,trail:·,extends:#,nbsp:·

" set wildmenu                   " make tab completion for files/buffers act like bash
" set wildmode=longest:full,full " show a list when pressing tab and complete

set title                      " change the terminal's title
set showcmd                    " show (partial) command in the last line of the screen
set modeline                   " allow files to include a 'mode line', to override vim defaults
set modelines=5                " check the first 5 lines for a modeline

set mouse=a

" Maintain undo history between sessions
set undofile
set undodir=$HOME/tmp/vimundo
set undolevels=1000
set undoreload=10000

" Try to show more context when scrolling
set scrolloff=5
set sidescrolloff=10

" There are not word dividers
set iskeyword+=$
set iskeyword+=_

let mapleader="\<Space>"

" Reload this config
nmap <leader>r :so $MYVIMRC<CR>


" Enter in normal mode saves
nmap <CR> :write!<CR>
" Except in the quickfix window, which we want the default behavior (open)
autocmd BufReadPost quickfix nnoremap <buffer> <CR> <CR>

if has('nvim') " https://github.com/neovim/neovim/issues/2048
    nmap <BS> <C-W>h
endif
" Easy window navigation
nmap <C-h> <C-w>h
nmap <C-j> <C-w>j
nmap <C-k> <C-w>k
nmap <C-l> <C-w>l
nmap <C-tab> <C-w>p

" Maps autocomplete to tab
" imap <Tab> <C-P>

let s:uname = system("uname")
if s:uname == "Darwin\n"
  " Make yank stick things on the OSX clipboard
  set clipboard=unnamed
else
  set clipboard+=unnamedplus
endif

" Strip trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e

" Identify the syntax highlighting group used at the cursor
map <F9> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
\ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
\ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>

" On window resize, re-balance the splits
autocmd VimResized * wincmd =

command! BW :bn|:bd#

"
" Plugin config
"

let g:vimwiki_list = [{'path': '~/Dropbox/vimwiki'}]

" ruby-vim
" highlight operators
let ruby_operators = 1 " Breaks HEREDOCs https://github.com/vim-ruby/vim-ruby/issues/358
" spellcheck inside strings
let ruby_spellcheck_strings = 1

" nicer indent settings
let g:ruby_indent_assignment_style = 'variable'
let g:ruby_indent_block_style = 'do'

" gh-line
let g:gh_open_command = 'xdg-open '
" let g:gh_open_command = 'fn() { echo "$@" | xclip -i; } fn '

" ack.vim
if executable('ag')
  let g:ackprg = 'ag --vimgrep --smart-case'
endif
cnoreabbrev ag Ack

nmap gag :Ack! <cword><cr>
nmap * :Ack! <cword><cr>


" FZF
" [Buffers] Jump to the existing window if possible
let g:fzf_buffers_jump = 1
let g:fzf_layout = { 'down': '~40%' }
" let g:fzf_layout = { 'window': '30new' }
let g:fzf_command_prefix = 'Fzf' " Commands start with Fzf, Eg :FzfGitFiles
nmap <C-Space> :FzfFiles<CR>
nmap <C-p> :FzfBuffers<CR>
nmap <C-@> <C-Space>
cnoreabbrev Rg FzfRg
cnoreabbrev Ag FzfRg

if executable('rg')
  let $FZF_DEFAULT_COMMAND='rg --files --smart-case --hidden --glob "!.git/*"'
  set grepprg=rg\ --vimgrep
  command! -bang -nargs=* Find call fzf#vim#grep('rg --column --line-number --no-heading --fixed-strings --ignore-case --hidden --follow --glob "!.git/*" --color "always" '.shellescape(<q-args>).'| tr -d "\017"', 1, <bang>0)
endif

" Airline
let g:airline_powerline_fonts=1
let g:airline_theme='base16_tomorrow'
let g:airline#extensions#tabline#enabled = 1

" Hide the filetype section (section 'y')
let g:airline#extensions#default#layout = [
    \ [ 'a', 'b', 'c' ],
    \ [ 'x',      'z', 'error', 'warning' ]
    \ ]

" Show buffer number, and allow shortcuts to jump to tabs
let g:airline#extensions#tabline#buffer_idx_mode = 1
nmap <leader>1 <Plug>AirlineSelectTab1
nmap <leader>2 <Plug>AirlineSelectTab2
nmap <leader>3 <Plug>AirlineSelectTab3
nmap <leader>4 <Plug>AirlineSelectTab4
nmap <leader>5 <Plug>AirlineSelectTab5
nmap <leader>6 <Plug>AirlineSelectTab6
nmap <leader>7 <Plug>AirlineSelectTab7
nmap <leader>8 <Plug>AirlineSelectTab8
nmap <leader>9 <Plug>AirlineSelectTab9
nmap <leader>[ <Plug>AirlineSelectPrevTab
nmap <leader>] <Plug>AirlineSelectNextTab

let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'
let g:airline#extensions#tabline#formatter = 'unique_tail_improved'

" ale linter

nmap <silent> <C-k> <Plug>(ale_previous_wrap)
nmap <silent> <C-j> <Plug>(ale_next_wrap)

let g:ale_sign_column_always = 1
let g:ale_sign_error = 'ﱥ'
let g:ale_sign_warning = ''

let g:ale_set_highlights = 0
let g:ale_lint_delay = 500

cnoreabbrev Fix ALEFix
let g:ale_fix_on_save = 1
let g:ale_fixers = {
\   'reason':     ['refmt'],
\   'ruby':       ['rubocop'],
\   'rust':       ['rustfmt'],
\   'go':         ['gofmt'],
\   'elm':        ['elm-format'],
\   'javascript': ['prettier'],
\}

let g:airline#extensions#ale#enabled = 1

" coc
" Use tab/shift-tab to autocomplete
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

" inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
" inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
" inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"


function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Better display for messages
set cmdheight=2
" don't give |ins-completion-menu| messages.
set shortmess+=c
" always show signcolumns
set signcolumn=yes
" Smaller updatetime for CursorHold & CursorHoldI
set updatetime=300


" tickfmt
let g:tick_fmt_command = "~/Code/go/bin/tickfmt"
let g:tick_fmt_experimental = 0

" git-gutter
let g:gitgutter_realtime=250

" " Neomake
" " run on file save
" autocmd! BufWritePost * Neomake
" let g:neomake_javascript_eslint_exe = $PWD .'/node_modules/.bin/eslint'
" let g:neomake_javascript_eslint_maker = {
"     \ 'args': ['--no-color', '--format', 'compact'],
"     \ 'errorformat': '%f: line %l\, col %c\, %m'
"     \ }
" let g:neomake_javascript_enabled_makers = ['eslint']

" Easy Align
" Start interactive EasyAlign in visual mode
vmap <Enter> <Plug>(EasyAlign)

" Start interactive EasyAlign with a Vim movement
nmap <Leader>a <Plug>(EasyAlign)

" vim-json
" Disable quote concealing
let g:vim_json_syntax_conceal = 0

" less noisy opposing parens
hi MatchParen cterm=bold ctermbg=none ctermfg=none

" Load all plugins now. ( from ~/.local/share/nvim/site/pack/... )
" Plugins need to be added to runtimepath before helptags can be generated.
packloadall
" Load all of the helptags now, after plugins have been loaded.
" All messages and errors will be ignored.
silent! helptags ALL
