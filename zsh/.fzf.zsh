# Setup fzf
# ---------
if [[ ! "$PATH" == */home/rando/.fzf/bin* ]]; then
  export PATH="$PATH:/home/rando/.fzf/bin"
fi

# Man path
# --------
if [[ ! "$MANPATH" == */home/rando/.fzf/man* && -d "/home/rando/.fzf/man" ]]; then
  export MANPATH="$MANPATH:/home/rando/.fzf/man"
fi

# Auto-completion
# ---------------
# [[ $- == *i* ]] && source "/home/rando/.fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
# source "/home/rando/.fzf/shell/key-bindings.zsh"

