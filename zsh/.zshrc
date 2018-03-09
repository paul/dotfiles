# Path to your oh-my-zsh configuration.
export ZSH=$HOME/.oh-my-zsh
export ZSH_CUSTOM=$HOME/.zsh

export BULLETTRAIN_CONTEXT_DEFAULT_USER=rando

if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
  export BULLETTRAIN_CONTEXT_SHOW=true
  export BULLETTRAIN_IS_SSH_CLIENT=true
fi

export BULLETTRAIN_PROMPT_ORDER=(
  status
  context
  dir
  ruby
  git
)

if [ $TILIX_ID ] || [ $VTE_VERSION ]; then
  source /etc/profile.d/vte.sh
fi

# Set to the name theme to load.
# Look in ~/.zsh/themes/
export ZSH_THEME="bullet-train"

if [[ `uname` == "Darwin" ]]; then
	OSX=1
fi

# Set to this to use case-sensitive completion
# export CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
# export DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# export DISABLE_LS_COLORS="true"

# zstyle :omz:plugins:chruby path /usr/share/chruby/chruby.sh
# zstyle :omz:plugins:chruby auto /usr/share/chruby/auto.sh


# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(
  # bundler
  # chruby
  colored-man
  docker
  gem
  git  # Adds too many dumb aliases
  git-extras
  gitfast # Completion
  git_remote_branch
  github
  #go
  #golang
  gpg-agent
  heroku
  # rails # Its just dumb aliases
  # ruby  # just aliases
  # vagrant
  zsh-syntax-highlighting
  ssh-agent
)

if [[ "$OSX" == "1" ]]; then
	plugins+=(brew osx)
fi

source $ZSH/oh-my-zsh.sh

# Customize to your needs...

# prefer GNU utils over the dumb BSD ones:
if [[ "$OSX" == "1" ]]; then
	PATH="$(brew --prefix coreutils)/libexec/gnubin:$PATH"
	MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"
fi

source ~/.aliases
eval `dircolors $HOME/.dir_colors`

# Base16 Shell
BASE16_SHELL="$HOME/.config/base16-shell/scripts/base16-oceanicnext.sh"
[[ -s $BASE16_SHELL ]] && source $BASE16_SHELL

# automatically enter directories without cd
setopt auto_cd
cdpath=(~/Code/tycho ~/Code)


unsetopt correct_all

export EDITOR=nvim
export BROWSER=vivaldi-stable

# Enable ssh-agent identities
zstyle :omz:plugins:ssh-agent identities id_rsyncnet

### Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"

[ -f /usr/local/share/zsh/site-functions/_aws ] && source /usr/local/share/zsh/site-functions/_aws

export RUBY_GC_MALLOC_LIMIT=1000000000
export RUBY_HEAP_SLOTS_GROWTH_FACTOR=1.25
# < 2.1.0
#export RUBY_HEAP_MIN_SLOTS=800000
#export RUBY_FREE_MIN=600000
# >= 2.1.0
export RUBY_GC_HEAP_FREE_SLOTS=800000
export RUBY_GC_HEAP_INIT_SLOTS=600000

# Newline before every prompt
precmd() { print "" }

eval "$(direnv hook zsh)"

if [[ "$OSX" == "1" ]]; then
	LUNCHY_DIR=$(dirname `gem which lunchy`)/../extras
	if [ -f $LUNCHY_DIR/lunchy-completion.zsh ]; then
		. $LUNCHY_DIR/lunchy-completion.zsh
	fi
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

[ -f ~/.iterm2_shell_integration.zsh ] && source ~/.iterm2_shell_integration.zsh

[ -f /usr/local/share/chruby/chruby.sh ] && source /usr/local/share/chruby/chruby.sh
[ -f /usr/local/share/chruby/auto.sh ] && source /usr/local/share/chruby/auto.sh

# For capybara-qt-webkit
export QMAKE=/usr/bin/qmake-qt5

export GOPATH=$HOME/Code/go

# npm -g installs for my user instead
NPM_PACKAGES="${HOME}/.npm-packages"
PATH="$PATH:$NPM_PACKAGES/bin"

# This goes last, cause lots of other things above add shit to the path
export PATH=./bin:$HOME/bin:./node_modules/.bin:$PATH

function fix_path() {
  local mypath="./bin:$HOME/bin:./node_modules/.bin"
  PATH=${PATH/$mypath//} # Remove my preferred paths from the string
  PATH=$mypath:$PATH     # Prepend it back on the beginning
  export PATH=$PATH
}

if [[ ! "$preexec_functions" == *fix_path* ]]; then
  preexec_functions+=("fix_path")
fi



