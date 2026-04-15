# ------------------
# default config
# ------------------

# 历史记录中有重复命令时，移除旧的
setopt HIST_IGNORE_ALL_DUPS

# 从 WORDCHARS 中移除路径分隔符
WORDCHARS=${WORDCHARS//[\/]/}

# 禁用每次 precmd 时自动重绑 widget，适用于
# zsh-autosuggestions 作为 ~/.zimrc 最后一个模块的情况
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# ------------------
# 自定义配置
# ------------------

export TMP_DIR=$HOME/.tmp

if [ ! -d "$TMP_DIR" ]; then
    mkdir "$TMP_DIR"
    echo "make ~/.tmp"
fi

# prompt — 在 vim.zsh 的 zvm_after_init() 中初始化，
# 避免与 zsh-vi-mode 的 zle-keymap-select 钩子冲突（FUNCNEST 溢出）
export STARSHIP_CONFIG="$HOME/.config/zsh/starship/starship.toml"

# editor
export EDITOR='nvim'

# Homebrew PATH — 仅在未初始化时执行。
# HOMEBREW_PREFIX 由 `brew shellenv` 导出；若已设置，说明 shellenv
# 已运行过（如 macOS 的 /etc/zprofile 或重复 source 本文件）。
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

