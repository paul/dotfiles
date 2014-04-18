
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
set pastetoggle=<F2> " when in insert mode, press <F2> to go to paste mode, where you can paste mass data that won't be autoindented
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
set wildignore=*.swp,*.bak,*.pyc,*.class
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

" Change the mapleader from \ to ,
let mapleader=","

" Easy window navigation
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l
map <C-tab> <C-w>p

" In normal mode, Space opens command mode
nnoremap <Space> :

" Make arrow keys useful again
map <down> <ESC>:bn<RETURN>
"map <right> <ESC>:Tlist<RETURN>
"map <left> <ESC>:NERDTreeToggle<RETURN>
map <up> <ESC>:bp<RETURN>

" Maps autocomplete to tab
imap <Tab> <C-P>



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
colorscheme solarized

" Add a ruler at 80 and 120 columns
set colorcolumn=80,120
hi ColorColumn ctermbg=234 guibg=#1D1E2C

" highlight conflict markers
match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'

" shortcut to jump to next conflict marker
nmap <silent> ,c /^\(<\\|=\\|>\)\{7\}\([^=].\+\)\?$<CR>


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

" Unite
let g:unite_source_history_yank_enable = 1
call unite#filters#matcher_default#use(['matcher_fuzzy', 'sorter_rank'])
nnoremap <leader>t :Unite -no-split -start-insert buffer file_rec/async:!<CR>

" Custom mappings for the unite buffer
autocmd FileType unite call s:unite_settings()
function! s:unite_settings()
" Play nice with supertab
  let b:SuperTabDisabled=1
" Enable navigation with control-j and control-k in insert mode
  imap <buffer> <C-j> <Plug>(unite_select_next_line)
  imap <buffer> <C-k> <Plug>(unite_select_previous_line)
endfunction

" Airline
let g:airline_powerline_fonts=1

