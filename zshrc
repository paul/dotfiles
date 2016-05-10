# Path to your oh-my-zsh configuration.
export ZSH=$HOME/.oh-my-zsh

# Set to the name theme to load.
# Look in ~/.oh-my-zsh/themes/
export ZSH_THEME="rando"

# Set to this to use case-sensitive completion
# export CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
# export DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# export DISABLE_LS_COLORS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(
  brew
  bundler
  chruby
  colored-man
  docker
  gem
  git
  git_remote_branch
  #github
  go
  golang
  #gpg-agent
  heroku
  osx
  rails
  ruby
  sublime
  #tmux
  #tmuxinator
  vagrant
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# Customize to your needs...

# prefer GNU utils over the dumb BSD ones:
PATH="$(brew --prefix coreutils)/libexec/gnubin:$PATH"

source ~/.aliases
eval `dircolors $HOME/.dir_colors`

# Base16 Shell
BASE16_SHELL="$HOME/.config/base16-shell/base16-tomorrow.dark.sh"
[[ -s $BASE16_SHELL ]] && source $BASE16_SHELL

# automatically enter directories without cd
setopt auto_cd
cdpath=(~/Code/tycho ~/Code/kapost ~/Code)

PATH=$HOME/bin:/usr/local/share/npm/bin:$PATH

unsetopt correct_all

# export PGHOST=/var/pgsql_socket
# using postgres-common instead

export EDITOR=vim
export PAGER=most

### Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"

source /usr/local/share/zsh/site-functions/_aws

export GOPATH=$HOME/Code/go

export RUBY_GC_MALLOC_LIMIT=1000000000
export RUBY_HEAP_SLOTS_GROWTH_FACTOR=1.25
# < 2.1.0
#export RUBY_HEAP_MIN_SLOTS=800000
#export RUBY_FREE_MIN=600000
# >= 2.1.0
export RUBY_GC_HEAP_FREE_SLOTS=800000
export RUBY_GC_HEAP_INIT_SLOTS=600000
export LD_PRELOAD=/usr/local/lib/libtcmalloc_minimal.dylib

# Newline before every prompt
precmd() { print "" }


# added by travis gem
[ -f /Users/rando/.travis/travis.sh ] && source /Users/rando/.travis/travis.sh
LUNCHY_DIR=$(dirname `gem which lunchy`)/../extras
if [ -f $LUNCHY_DIR/lunchy-completion.zsh ]; then
  . $LUNCHY_DIR/lunchy-completion.zsh
fi

