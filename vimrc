
execute pathogen#infect()
syntax on
filetype plugin indent on

" Sensible is some nice defaults, but make sure we load it first
" so everything in this file overrides it
runtime! plugin/sensible.vim

set wrap                       " wrap lines
set expandtab
"set tabstop=2                 " a tab is TWO spaces
set softtabstop=2
set shiftwidth=2
set backspace=indent,eol,start " allow backspacing over everything in insert mode
set autoindent                 " always set autoindenting on
"set copyindent                " copy the previous indentation on autoindenting
set number                     " always show line numbers
set shiftround                 " use multiple of shiftwidth when indenting with '<' and '>'
set showmatch                  " set show matching parenthesis

"set ignorecase      " ignore case when searching
set smartcase        " ignore case if search pattern is all lowercase, case-sensitive otherwise
set smarttab         " insert tabs on the start of a line according to shiftwidth, not tabstop
set scrolloff=5      " keep 4 lines off the edges of the screen when scrolling
set hlsearch         " highlight search terms
set incsearch        " show search matches as you type
set list             " show invisible characters
set listchars=tab:»·,trail:·,extends:#,nbsp:·
set mouse=a          " enable using the mouse if terminal emulator supports it (xterm does)


set hidden                     " hide buffers instead of closing them this
                               " means that the current buffer can be put
                               " to background without being written; and
                               " that marks and undo history are preserved
set switchbuf=useopen,usetab   " reveal already opened files from the
                               " quickfix window instead of opening new buffers
set history=1000               " remember more commands and search history
set undolevels=1000            " use many muchos levels of undo
set directory=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp " store swap files in one of these directories
set viminfo='20,\"80           " read/write a .viminfo file, don't store more than 80 lines of registers
set wildmenu                   " make tab completion for files/buffers act like bash
set wildmode=longest:full,full " show a list when pressing tab and complete
"set wildignore=*.swp,*.bak,*.pyc,*.class,*/tmp/*,*.log
set title                      " change the terminal's title
"set visualbell                " don't beep
set noerrorbells               " don't beep
set showcmd                    " show (partial) command in the last line of the screen
set modeline                   " allow files to include a 'mode line', to override vim defaults
set modelines=5                " check the first 5 lines for a modeline

" Try to show more context when scrolling
set scrolloff=5
set sidescrolloff=10

" There are not word dividers
set iskeyword+=$
set iskeyword+=_

" Dont pollute with swapfiles
set noswapfile
set nobackup

" Since I never use the ; key anyway, this is a real optimization for almost
" all Vim commands, since we don't have to press that annoying Shift key that
" slows the commands down
nnoremap ; :

" Change the mapleader from \ to spacebar
let mapleader="\<Space>"

" Useful leader shortcuts
nnoremap <Leader>w :w<CR>


" Easy window navigation
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l
map <C-tab> <C-w>p

" Make arrow keys useful again
"map <down> <ESC>:bn<RETURN>
"map <right> <ESC>:Tlist<RETURN>
map <left> <ESC>:NERDTreeToggle<RETURN>
map <up> <ESC>:MBEToggle<RETURN>

" Maps autocomplete to tab
imap <Tab> <C-P>

" Make yank stick things on the OSX clipboard
set clipboard=unnamed


" Strip trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e


"""
" Colors & Syntax
"""

if has("gui_running")
  let g:solarized_termcolors=256
" No audible bell
  set vb

" No toolbar
  set guioptions-=T
" no scrollbars
  set guioptions-=r
  set guioptions-=R
  set guioptions-=l
  set guioptions-=L
  set guioptions-=b

" Clipboard when visual select
  set guioptions+=a

" Use console dialogs
  set guioptions+=c
endif

set background=dark
" colorscheme solarized
colorscheme base16-tomorrow

" Add a ruler at 80 and 120 columns
set colorcolumn=80,120
hi ColorColumn ctermbg=234 guibg=#1D1E2C

" highlight conflict markers
match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'

" shortcut to jump to next conflict marker
nmap <silent> ,c /^\(<\\|=\\|>\)\{7\}\([^=].\+\)\?$<CR>

"""
" Files to ignore
"""

set wildignore=*.o,*.obj,*~,*.pyc "stuff to ignore when tab completing
set wildignore+=.env
set wildignore+=.env[0-9]+
set wildignore+=.env-pypy
set wildignore+=.git,.gitkeep
set wildignore+=.tmp
set wildignore+=.coverage
set wildignore+=*DS_Store*
set wildignore+=.sass-cache/
set wildignore+=__pycache__/
set wildignore+=.webassets-cache/
set wildignore+=vendor/rails/**
set wildignore+=vendor/cache/**
set wildignore+=*.gem
set wildignore+=log/**
set wildignore+=tmp/**
set wildignore+=.tox/**
set wildignore+=.idea/**
set wildignore+=.vagrant/**
set wildignore+=.coverage/**
set wildignore+=*.egg,*.egg-info
set wildignore+=*.png,*.jpg,*.gif
set wildignore+=*.so,*.swp,*.zip,*/.Trash/**,*.pdf,*.dmg,*/Library/**,*/.rbenv/**
set wildignore+=*/.nx/**,*.app

"""
" Plugins
"""

" Have ack.vim use ag
let g:ackprg = 'ag --nogroup --nocolor --column'

" Easy Align
" Start interactive EasyAlign in visual mode
vmap <Enter> <Plug>(EasyAlign)

" Start interactive EasyAlign with a Vim movement
nmap <Leader>a <Plug>(EasyAlign)

" fuzzy-search all files
let g:ctrlp_user_command = 'ag %s -i --nocolor --nogroup --hidden
      \ --ignore .git
      \ --ignore .svn
      \ --ignore .hg
      \ --ignore .DS_Store
      \ --ignore "**/tmp/**"
      \ --ignore "**/node_modules/**"
      \ -g ""'
nnoremap <leader>t :CtrlPMixed<CR>
let g:ctrlp_mruf_relative = 1 " Ignore MRU files in other directories
"let g:ctlrp_map = '<Leader>t'
"let g:ctlrp_cmd = 'CtrlPMixed'

" Airline
let g:airline_powerline_fonts=1

