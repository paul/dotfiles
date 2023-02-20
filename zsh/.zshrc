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

# if [ $TILIX_ID ] || [ $VTE_VERSION ]; then
#   source /etc/profile.d/vte.sh
# fi

# Set to the name theme to load.
# Look in ~/.zsh/themes/
export ZSH_THEME="bullet-train"

if [[ `uname` == "Darwin" ]]; then
	OSX=1
fi

# Disable the ^S shortcut in terminals
stty -ixon

# Set to this to use case-sensitive completion
# export CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
# export DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# export DISABLE_LS_COLORS="true"

zstyle :omz:plugins:chruby path ~/.local/share/chruby/chruby.sh
zstyle :omz:plugins:chruby auto ~/.local/share/chruby/auto.sh

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(
  # asdf
  # bundler
  chruby
  docker
  gem
  # git  # Adds too many dumb aliases
  git-extras
  gitfast # Completion
  github
  #go
  #golang
  gpg-agent
  heroku
  # rails # Its just dumb aliases
  # ruby  # just aliases
  # vagrant
  # ssh-agent
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

(( $+commands[dircolors] )) && eval `dircolors $HOME/.dir_colors`

# Base16 Shell
# BASE16_SHELL="$HOME/.config/base16-shell/"
# [ -n "$PS1" ] && \
#     [ -s "$BASE16_SHELL/profile_helper.sh" ] && \
#         eval "$("$BASE16_SHELL/profile_helper.sh")"

# automatically enter directories without cd
setopt auto_cd
cdpath=(~/Code)

unsetopt correct_all

export EDITOR=nvim
export BROWSER=vivaldi-stable

# Enable ssh-agent identities
zstyle :omz:plugins:ssh-agent identities id_rsyncnet
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

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

(( $+commands[direnv] )) && eval "$(direnv hook zsh)"

FZF_DEFAULT_COMMAND='rg --files --hidden'

# Fedora provides a package
[ -f /usr/share/fzf/shell/key-bindings.zsh ] && source /usr/share/fzf/shell/key-bindings.zsh

# For capybara-qt-webkit
export QMAKE=/usr/bin/qmake-qt5

export GOPATH=$HOME/Code/go

# npm -g installs for my user instead
export NPM_PACKAGES="${HOME}/node_modules"

# Always my sure my paths are at the front
typeset -U path # make path unique
function fix_path() {
  path=(./bin ~/bin ~/.local/bin /home/rando/.cargo/bin $GOPATH/bin $NPM_PACKAGES/bin ~/.local/share/npm/bin "$path[@]")
}

if [[ ! "$preexec_functions" == *fix_path* ]]; then
  preexec_functions+=("fix_path")
fi

# Don't show less when < 1 page of output
# export LESS="--quit-if-one-screen $LESS"

# Allow C-\ to be used for other things than SIGQUIT
stty quit undef

# export NVS_HOME="$HOME/.nvs"
# [ -s "$NVS_HOME/nvs.sh" ] && . "$NVS_HOME/nvs.sh"

# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ASDF
[ -f "$HOME/.asdf/asdf.sh" ] && . "$HOME/.asdf/asdf.sh"
[ -f /opt/homebrew/opt/asdf/libexec/asdf.sh ] && . /opt/homebrew/opt/asdf/libexec/asdf.sh

