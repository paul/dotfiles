# Path to your oh-my-zsh configuration.
export ZSH=$HOME/.oh-my-zsh

if [[ `uname` == "Darwin" ]]; then
	OSX=1
fi

# Disable the ^S shortcut in terminals
stty -ixon <$TTY >$TTY

# Allow C-\ to be used for other things than SIGQUIT 
stty quit undef <$TTY >$TTY

# Set to this to use case-sensitive completion
# export CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
# export DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# export DISABLE_LS_COLORS="true"

# Skip all plugin aliases
zstyle ':omz:plugins:*' aliases no

plugins=(
  # asdf
  # bundler
  # chruby
  # docker
  gem
  # git  # Adds too many dumb aliases
  git-extras
  gitfast # Completion
  github
  #go
  #golang
  gpg-agent
  heroku
  mise
  # rails # Its just dumb aliases
  # ruby  # just aliases
  # vagrant
  # ssh-agent

  auto-notify # https://github.com/MichaelAquilina/zsh-auto-notify
)

if [[ "$OSX" == "1" ]]; then
	plugins+=(brew)
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

# Always my sure my paths are at the front
typeset -U path # make path unique
function fix_path() {
  path=(./bin ~/bin ~/.local/bin /home/rando/.cargo/bin $GOPATH/bin $NPM_PACKAGES/bin ~/.local/share/npm/bin /usr/pgsql-16/bin "$path[@]")
}

if [[ ! "$preexec_functions" == *fix_path* ]]; then
  preexec_functions+=("fix_path")
fi

# automatically enter directories without cd
setopt auto_cd
cdpath=(~/Code)

unsetopt correct_all

export EDITOR=nvim
export BROWSER=firefox

# Enable ssh-agent identities
zstyle :omz:plugins:ssh-agent identities id_rsyncnet
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

export RUBY_GC_MALLOC_LIMIT=1000000000
export RUBY_HEAP_SLOTS_GROWTH_FACTOR=1.25
export RUBY_GC_HEAP_FREE_SLOTS=800000
export RUBY_GC_HEAP_INIT_SLOTS=600000

(( $+commands[direnv] )) && eval "$(direnv hook zsh)"
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
(( $+commands[atuin] )) && eval "$(atuin init zsh)"

# FZF
FZF_DEFAULT_COMMAND='rg --files --hidden'

# Fedora provides a package
[ -f /usr/share/fzf/shell/key-bindings.zsh ] && source /usr/share/fzf/shell/key-bindings.zsh

# JQ
# JQ colors has null the same as background for some reason
# null:false:true:number:string:array:object
export JQ_COLORS="1;30:0;37:0;37:0;34:0;33:0;37:0;37"

# For capybara-qt-webkit
export QMAKE=/usr/bin/qmake-qt5

# GO
export GOPATH=$HOME/Code/go

# NPM
# npm -g installs for my user instead
export NPM_PACKAGES="${HOME}/node_modules"

# Podman
# By default, its stores in $XDG_RUNTIME_DIR, which on fedora is /run/user/1000, which is tmpfs and
# gets emptied every reboot. Store it somewhere more permanent.
REGISTRY_AUTH_FILE=$HOME/.config/containers/auth.json

# Don't show less when < 1 page of output
export LESS="--quit-if-one-screen $LESS"

#compdef gt
###-begin-gt-completions-###
#
# yargs command completion script
#
# Installation: gt completion >> ~/.zshrc
#    or gt completion >> ~/.zprofile on OSX.
#
_gt_yargs_completions()
{
  local reply
  local si=$IFS
  IFS=$'
' reply=($(COMP_CWORD="$((CURRENT-1))" COMP_LINE="$BUFFER" COMP_POINT="$CURSOR" gt --get-yargs-completions "${words[@]}"))
  IFS=$si
  _describe 'values' reply
}
compdef _gt_yargs_completions gt
###-end-gt-completions-###

# Starship prompt
eval "$(starship init zsh)"

# # bun completions
# [ -s "/home/rando/.bun/_bun" ] && source "/home/rando/.bun/_bun"
#
# # bun
# export BUN_INSTALL="$HOME/.bun"
# export PATH="$BUN_INSTALL/bin:$PATH"

cursor() {
  # Run the cursor command and suppress background process output completely
  (nohup $HOME/Applications/Cursor-0.48.6-x86_64.AppImage "$@" >/dev/null 2>&1 &)
}

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/usr/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/usr/etc/profile.d/conda.sh" ]; then
        . "/usr/etc/profile.d/conda.sh"
    else
        export PATH="/usr/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

