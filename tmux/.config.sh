#!/bin/bash
set -e
: "${DOTFILES_DIR:?must be set by install.sh}"
# tmux 配置链接 — 由 install.sh 调用，DOTFILES_DIR 由父进程导出
rm -rf "$HOME/.config/tmux"
ln -sfn "$DOTFILES_DIR/tmux" "$HOME/.config/tmux"
printf "  \033[36m%-24s\033[0m \033[2m→\033[0m \033[2;3m%s\033[0m\n" "~/.config/tmux/" "tmux/"

# TPM（tmux 插件管理器）bootstrap
# 因 tmux.conf 走 XDG 路径（~/.config/tmux/tmux.conf），TPM 会把插件装到
# ~/.config/tmux/plugins/。该目录物理上落在仓库 tmux/plugins/，由
# tmux/.gitignore 排除，不入库。
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR" >/dev/null 2>&1
  printf "  \033[2mTPM 已安装到 ~/.config/tmux/plugins/tpm/\033[0m\n"
fi

# headless 安装所有 @plugin 声明的插件（已装的自动跳过）
# install_plugins 是纯 bash 脚本，直接解析 tmux.conf，不依赖 tmux server
# 必须显式 export TMUX_PLUGIN_MANAGER_PATH，否则 TPM 的 shared.sh 会 fallback
# 到 ~/.tmux/plugins/（默认值），插件不会落到 XDG 路径
if [[ -x "$TPM_DIR/bin/install_plugins" ]]; then
  TMUX_PLUGIN_MANAGER_PATH="$HOME/.config/tmux/plugins/" \
    "$TPM_DIR/bin/install_plugins" >/dev/null 2>&1 || true
  printf "  \033[2mtmux 插件已安装到 ~/.config/tmux/plugins/\033[0m\n"
fi

# reload 配置（若 server 在跑）
if command -v tmux &>/dev/null && tmux list-sessions &>/dev/null; then
  tmux source-file "$HOME/.config/tmux/tmux.conf" 2>/dev/null && \
    printf "  \033[2mtmux server 已重载配置\033[0m\n"
fi
