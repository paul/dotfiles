# Setup fzf
# ---------
# if [[ ! "$PATH" == */home/rando/Code/dotfiles/zsh/.fzf/bin* ]]; then
#   export PATH="$PATH:/home/rando/Code/dotfiles/zsh/.fzf/bin"
# fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/usr/share/fzf/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "/usr/share/fzf/shell/key-bindings.zsh"

