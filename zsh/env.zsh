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

# prompt — initialized in zvm_after_init() in vim.zsh to avoid
# zle-keymap-select hook conflicts with zsh-vi-mode (FUNCNEST overflow)
export STARSHIP_CONFIG="$HOME/.config/zsh/starship/starship.toml"

# editor
export EDITOR='nvim'

# Homebrew PATH — only run when not already initialized.
# HOMEBREW_PREFIX is exported by `brew shellenv`; if it's set, shellenv has
# already run (e.g. via /etc/zprofile on macOS or a prior source of this file).
if [[ -z "$HOMEBREW_PREFIX" ]]; then
    if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# path
export PATH=$PATH:$HOME/.local/bin

# zoxide
eval "$(zoxide init zsh)"

