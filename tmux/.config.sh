#!/bin/bash
set -e
: "${DOTFILES_DIR:?must be set by install.sh}"
# tmux 配置链接 — 由 install.sh 调用，DOTFILES_DIR 由父进程导出
rm -rf "$HOME/.config/tmux"
ln -sfn "$DOTFILES_DIR/tmux" "$HOME/.config/tmux"
printf "  \033[36m%-24s\033[0m \033[2m→\033[0m \033[2;3m%s\033[0m\n" "~/.config/tmux/" "tmux/"

# 若 tmux server 正在运行，同步 reload 配置（tmux 不会自动重读 tmux.conf）
if command -v tmux &>/dev/null && tmux list-sessions &>/dev/null; then
  tmux source-file "$HOME/.config/tmux/tmux.conf" 2>/dev/null && \
    printf "  \033[2mtmux server 已重载配置\033[0m\n"
fi
