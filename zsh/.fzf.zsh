# Setup fzf
# ---------
if [[ ! "$PATH" == */Users/rando/Code/dotfiles/zsh/.fzf/bin* ]]; then
  export PATH="$PATH:/Users/rando/Code/dotfiles/zsh/.fzf/bin"
fi

# Man path
# --------
if [[ ! "$MANPATH" == */Users/rando/Code/dotfiles/zsh/.fzf/man* && -d "/Users/rando/Code/dotfiles/zsh/.fzf/man" ]]; then
  export MANPATH="$MANPATH:/Users/rando/Code/dotfiles/zsh/.fzf/man"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/Users/rando/Code/dotfiles/zsh/.fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "/Users/rando/Code/dotfiles/zsh/.fzf/shell/key-bindings.zsh"

