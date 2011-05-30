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
plugins=(brew bundler git rails3 ruby vagrant)

source $ZSH/oh-my-zsh.sh

# Customize to your needs...

source ~/.aliases

[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"

# automatically enter directories without cd
setopt auto_cd
cdpath=(~/Code ~/Code/api)

PATH=$HOME/bin:/usr/local/bin:$PATH

unsetopt correct_all

source ~/bin/ssbe-web.zsh

# prefer GNU utils over the dumb BSD ones:
source /usr/local/Cellar/coreutils/8.12/aliases

