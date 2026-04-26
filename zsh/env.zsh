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

# locale — 强制 UTF-8，避免远端 LANG=C 时 zsh/starship 把中文和 Nerd Font
# 图标渲染成下划线。kitten ssh 不转发 LANG，在 env.zsh 里 export 让本地
# 远端 zsh 都自带 UTF-8，不依赖 sshd AcceptEnv。远端需已生成 en_US.UTF-8
# （Ubuntu/Debian 上 sudo locale-gen en_US.UTF-8）
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# XDG — 统一配置目录，让 macOS 上的 lazygit 等工具也使用 ~/.config/<app>
# 而非各自的系统默认路径（如 ~/Library/Application Support/lazygit）
export XDG_CONFIG_HOME="$HOME/.config"

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

# trash-cli (keg-only，需手动加入 PATH)
if [[ -d /opt/homebrew/opt/trash-cli/bin ]]; then
    export PATH="/opt/homebrew/opt/trash-cli/bin:$PATH"
elif [[ -d /home/linuxbrew/.linuxbrew/opt/trash-cli/bin ]]; then
    export PATH="/home/linuxbrew/.linuxbrew/opt/trash-cli/bin:$PATH"
fi

# zoxide
eval "$(zoxide init zsh)"

