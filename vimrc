" Use vim settings, rather then vi settings (much better!)
" This must be first, because it changes other options as a side effect.
set nocompatible

" Use pathogen to easily modify the runtime path to include all plugins under
" the ~/.vim/bundle directory
call pathogen#helptags()
call pathogen#runtime_append_all_bundles()

" Editing behaviour {{{
filetype on                     " set filetype stuff to on
filetype plugin on
filetype indent on

set wrap                        " wrap lines
set expandtab
"set tabstop=2                   " a tab is TWO spaces
set softtabstop=2
set shiftwidth=2
set backspace=indent,eol,start  " allow backspacing over everything in insert mode
set autoindent                  " always set autoindenting on
"set copyindent                  " copy the previous indentation on autoindenting
set number                      " always show line numbers
set shiftround                  " use multiple of shiftwidth when indenting with '<' and '>'
set showmatch                   " set show matching parenthesis
" set foldenable                  " enable folding
" set foldcolumn=2                " add a fold column
" set foldmethod=marker           " detect triple-{ style fold markers
" set foldmethod=syntax
" let g:SimpleFold_use_subfolds = 0
" set foldopen=block,hor,insert,jump,mark,percent,quickfix,search,tag,undo
                                " which commands trigger auto-unfold
"set ignorecase                  " ignore case when searching
set smartcase                   " ignore case if search pattern is all lowercase,
                                "    case-sensitive otherwise
set smarttab                    " insert tabs on the start of a line according to
                                "    shiftwidth, not tabstop
set scrolloff=4                 " keep 4 lines off the edges of the screen when scrolling
set hlsearch                    " highlight search terms
set incsearch                   " show search matches as you type
set list                        " show invisible characters
set listchars=tab:»·,trail:·,extends:#,nbsp:·
set pastetoggle=<F2>            " when in insert mode, press <F2> to go to
                                "    paste mode, where you can paste mass data
                                "    that won't be autoindented
set mouse=a                     " enable using the mouse if terminal emulator
                                "    supports it (xterm does)

set notitle

" Speed up scrolling of the viewport slightly
nnoremap <C-e> 2<C-e>
nnoremap <C-y> 2<C-y>

" Strip trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e

" }}}

" Editor layout {{{
set termencoding=utf-8
set encoding=utf-8
set lazyredraw                  " don't update the display while executing macros
set laststatus=2                " tell VIM to always put a status line in, even
                                "    if there is only one window
"set showtabline=2               " show a tabbar on top, always
"set cmdheight=2                 " use a status bar that is 2 rows high
" }}}

" Vim behaviour {{{
set hidden                      " hide buffers instead of closing them this
                                "    means that the current buffer can be put
                                "    to background without being written; and
                                "    that marks and undo history are preserved
set switchbuf=useopen,usetab    " reveal already opened files from the
                                " quickfix window instead of opening new
                                " buffers
set history=1000                " remember more commands and search history
set undolevels=1000             " use many muchos levels of undo
set nobackup                    " do not keep backup files, it's 70's style cluttering
set noswapfile                  " do not write annoying intermediate swap files,
                                "    who did ever restore from swap files anyway?
set directory=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
                                " store swap files in one of these directories
set viminfo='20,\"80            " read/write a .viminfo file, don't store more
                                "    than 80 lines of registers
set wildmenu                    " make tab completion for files/buffers act like bash
set wildmode=longest:full,full  " show a list when pressing tab and complete
set wildignore=*.swp,*.bak,*.pyc,*.class
set title                       " change the terminal's title
"set visualbell                  " don't beep
set noerrorbells                " don't beep
set showcmd                     " show (partial) command in the last line of the screen
                                "    this also shows visual selection info
set modeline                    " allow files to include a 'mode line', to
                                "    override vim defaults
set modelines=5                 " check the first 5 lines for a modeline

" Try to show more context when scrolling
set scrolloff=5
set sidescrolloff=10

" There are not word dividers
set iskeyword+=$
set iskeyword+=_

" Dont pollute with swapfiles
set noswapfile
set nobackup

" }}}

" Highlighting {{{
set background=dark
if &t_Co >= 256 || has("gui_running")
   colorscheme ir_black
endif

if &t_Co > 2 || has("gui_running")
   syntax on                    " switch syntax highlighting on, when the terminal has colors
   colorscheme ir_black
endif
" }}}

" Shortcut mappings {{{
" Since I never use the ; key anyway, this is a real optimization for almost
" all Vim commands, since we don't have to press that annoying Shift key that
" slows the commands down
nnoremap ; :

" Use Q for formatting the current paragraph (or visual selection)
vmap Q gq
nmap Q gqap

" make p in Visual mode replace the selected text with the yank register
vnoremap p <Esc>:let current_reg = @"<CR>gvdi<C-R>=current_reg<CR><Esc>

" Swap implementations of ` and ' jump to markers
" By default, ' jumps to the marked line, ` jumps to the marked line and
" column, so swap them
nnoremap ' `
nnoremap ` '

" Change the mapleader from \ to ,
let mapleader=","

" Use the damn hjkl keys
" map <up> <nop>
" map <down> <nop>
" map <left> <nop>
" map <right> <nop>
" Remap j and k to act as expected when used on long, wrapped, lines
" nnoremap j gj
" nnoremap k gk

" Easy window navigation
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l
map <C-tab> <C-w>p

nnoremap <Space> :

" Make arrow keys useful again
map <down> <ESC>:bn<RETURN>
"map <right> <ESC>:Tlist<RETURN>
"map <left> <ESC>:NERDTreeToggle<RETURN>
map <up> <ESC>:bp<RETURN>

" Complete whole filenames/lines with a quicker shortcut key in insert mode
imap <C-f> <C-x><C-f>
imap <C-l> <C-x><C-l>

" Use ,d (or ,dd or ,dj or 20,dd) to delete a line without adding it to the
" yanked stack (also, in visual mode)
nmap <silent> ,d "_d
vmap <silent> ,d "_d

" Edit the vimrc file
nmap <silent> ,ev :e $MYVIMRC<CR>
nmap <silent> ,sv :so $MYVIMRC<CR>

" Clears the search register
nmap <silent> ,/ :let @/=""<CR>

" Quick alignment of text
nmap ,al :left<CR>
nmap ,ar :right<CR>
nmap ,ac :center<CR>

" Sudo to write
cmap w!! w !sudo tee % >/dev/null

" Pull word under cursor into LHS of a substitute
nmap ,z :%s#\<<C-r>=expand("<cword>")<CR>\>#

" Maps autocomplete to tab
imap <Tab> <C-P>


" }}}

" Conflict markers {{{
" highlight conflict markers
match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'

" shortcut to jump to next conflict marker
nmap <silent> ,c /^\(<\\|=\\|>\)\{7\}\([^=].\+\)\?$<CR>
" }}}

