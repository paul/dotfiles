
# Setting ag as the default source for fzf
export FZF_DEFAULT_COMMAND='ag --hidden -g ""'

# Setup fzf
# ---------
if [[ ! "$PATH" == */Users/rando/.fzf/bin* ]]; then
  export PATH="$PATH:/Users/rando/.fzf/bin"
fi

# Man path
# --------
if [[ ! "$MANPATH" == */Users/rando/.fzf/man* && -d "/Users/rando/.fzf/man" ]]; then
  export MANPATH="$MANPATH:/Users/rando/.fzf/man"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/Users/rando/.fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "/Users/rando/.fzf/shell/key-bindings.zsh"

