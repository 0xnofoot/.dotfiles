# ------------------
# Default Config
# ------------------

# Remove older command from the history if a duplicate is to be added.
setopt HIST_IGNORE_ALL_DUPS

# Remove path separator from WORDCHARS.
WORDCHARS=${WORDCHARS//[\/]/}

# Disable automatic widget re-binding on each precmd. This can be set when
# zsh-users/zsh-autosuggestions is the last module in your ~/.zimrc.
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# ------------------
# Private Config
# ------------------

export TMP_DIR=$HOME/.tmp

if [ ! -d "$TMP_DIR" ]; then
    mkdir "$TMP_DIR"
    echo "make ~/.tmp"
fi

# prompt
eval "$(starship init zsh)"

# editor
export EDITOR='nvim'

# path
export PATH=$PATH:$HOME/.local/bin

# zoxide
eval "$(zoxide init zsh)"

