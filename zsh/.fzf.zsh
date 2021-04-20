# Setup fzf
# ---------
if [[ ! "$PATH" == */home/rando/Code/dotfiles/zsh/.fzf/bin* ]]; then
  export PATH="${PATH:+${PATH}:}/home/rando/Code/dotfiles/zsh/.fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/home/rando/Code/dotfiles/zsh/.fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "/home/rando/Code/dotfiles/zsh/.fzf/shell/key-bindings.zsh"
