# Path to your oh-my-zsh configuration.
export ZSH=$HOME/.oh-my-zsh
export ZSH_CUSTOM=$HOME/.zsh

export BULLETTRAIN_PROMPT_ORDER=(
  status
  dir
  ruby
  git
)



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

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(
  bundler
  chruby
  colored-man
  docker
  gem
  git
  git_remote_branch
  #github
  #go
  #golang
  #gpg-agent
  heroku
  rails
  ruby
  #tmux
  #tmuxinator
  vagrant
  zsh-syntax-highlighting
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
BASE16_SHELL="$HOME/.config/base16-shell/scripts/base16-tomorrow-night.sh"
[[ -s $BASE16_SHELL ]] && source $BASE16_SHELL

# automatically enter directories without cd
setopt auto_cd
cdpath=(~/Code/tycho ~/Code/kapost ~/Code)

PATH=$HOME/bin:/usr/local/share/npm/bin:$PATH

unsetopt correct_all

export EDITOR=nvim

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

# GPG Agent
if [[ "$OSX" == "1" ]]; then
	if test -f ~/.gnupg/.gpg-agent-info -a -n "$(pgrep gpg-agent)"; then
		source ~/.gnupg/.gpg-agent-info
		export GPG_AGENT_INFO
	else
		eval $(gpg-agent --daemon --write-env-file ~/.gnupg/.gpg-agent-info)
	fi
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

[ -f ~/.iterm2_shell_integration.zsh ] && source ~/.iterm2_shell_integration.zsh

[ -f /usr/share/chruby/chruby.sh ] && source /usr/share/chruby/chruby.sh
