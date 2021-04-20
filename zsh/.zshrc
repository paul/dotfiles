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
eval `dircolors $HOME/.dir_colors`

# Base16 Shell
# BASE16_SHELL="$HOME/.config/base16-shell/"
# [ -n "$PS1" ] && \
#     [ -s "$BASE16_SHELL/profile_helper.sh" ] && \
#         eval "$("$BASE16_SHELL/profile_helper.sh")"

# automatically enter directories without cd
setopt auto_cd
cdpath=(~/Code/tycho ~/Code)


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

eval "$(direnv hook zsh)"

if [[ "$OSX" == "1" ]]; then
	LUNCHY_DIR=$(dirname `gem which lunchy`)/../extras
	if [ -f $LUNCHY_DIR/lunchy-completion.zsh ]; then
		. $LUNCHY_DIR/lunchy-completion.zsh
	fi
fi

FZF_DEFAULT_COMMAND='rg --files --hidden'

# Fedora provides a package
[ -f /usr/share/fzf/shell/key-bindings.zsh ] && source /usr/share/fzf/shell/key-bindings.zsh

# GIT heart FZF
# -------------

is_in_git_repo() {
  git rev-parse HEAD > /dev/null 2>&1
}

fzf-down() {
  fzf --height 50% "$@" --border
}

gf() {
  is_in_git_repo || return
  git -c color.status=always status --short |
  fzf-down -m --ansi --nth 2..,.. \
    --preview '(git diff --color=always -- {-1} | sed 1,4d; cat {-1}) | head -500' |
  cut -c4- | sed 's/.* -> //'
}

gb() {
  is_in_git_repo || return
  git branch -a --color=always | grep -v '/HEAD\s' | sort |
  fzf-down --ansi --multi --tac --preview-window right:70% \
    --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1) | head -'$LINES |
  sed 's/^..//' | cut -d' ' -f1 |
  sed 's#^remotes/##'
}

gt() {
  is_in_git_repo || return
  git tag --sort -version:refname |
  fzf-down --multi --preview-window right:70% \
    --preview 'git show --color=always {} | head -'$LINES
}

gh() {
  is_in_git_repo || return
  git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always |
  fzf-down --ansi --no-sort --reverse --multi --bind 'ctrl-s:toggle-sort' \
    --header 'Press CTRL-S to toggle sort' \
    --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | xargs git show --color=always | head -'$LINES |
  grep -o "[a-f0-9]\{7,\}"
}

gr() {
  is_in_git_repo || return
  git remote -v | awk '{print $1 "\t" $2}' | uniq |
  fzf-down --tac \
    --preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" {1} | head -200' |
  cut -d$'\t' -f1
}

join-lines() {
  local item
  while read item; do
    echo -n "${(q)item} "
  done
}

bind-git-helper() {
  local c
  for c in $@; do
    eval "fzf-g$c-widget() { local result=\$(g$c | join-lines); zle reset-prompt; LBUFFER+=\$result }"
    eval "zle -N fzf-g$c-widget"
    eval "bindkey '^g^$c' fzf-g$c-widget"
  done
}
bind-git-helper f b t r h
unset -f bind-git-helper

# For capybara-qt-webkit
export QMAKE=/usr/bin/qmake-qt5

export GOPATH=$HOME/Code/go

# npm -g installs for my user instead
export NPM_PACKAGES="${HOME}/node_modules"

# Always my sure my paths are at the front
typeset -U path # make path unique
function fix_path() {
  path=(./bin ~/bin ~/.local/bin /home/rando/.cargo/bin ./node_modules/bin $NPM_PACKAGES/bin ~/.local/share/npm/bin "$path[@]")
}

if [[ ! "$preexec_functions" == *fix_path* ]]; then
  preexec_functions+=("fix_path")
fi

# Don't show less when < 1 page of output
# export LESS="--quit-if-one-screen $LESS"

# Allow C-\ to be used for other things than SIGQUIT
stty quit undef

# tabtab source for serverless package
# uninstall by removing these lines or running `tabtab uninstall serverless`
[[ -f /home/rando/Code/textus/node_modules/tabtab/.completions/serverless.zsh ]] && . /home/rando/Code/textus/node_modules/tabtab/.completions/serverless.zsh
# tabtab source for sls package
# uninstall by removing these lines or running `tabtab uninstall sls`
[[ -f /home/rando/Code/textus/node_modules/tabtab/.completions/sls.zsh ]] && . /home/rando/Code/textus/node_modules/tabtab/.completions/sls.zsh

# added by travis gem
[ -f /home/rando/.travis/travis.sh ] && source /home/rando/.travis/travis.sh

export NVS_HOME="$HOME/.nvs"
[ -s "$NVS_HOME/nvs.sh" ] && . "$NVS_HOME/nvs.sh"

# Added by cpan
PATH="/home/rando/perl5/bin${PATH:+:${PATH}}"; export PATH;
PERL5LIB="/home/rando/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="/home/rando/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"/home/rando/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=/home/rando/perl5"; export PERL_MM_OPT;
