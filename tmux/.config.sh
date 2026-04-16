#!/bin/bash
set -e
# tmux 配置链接 — 由 install.sh 调用，DOTFILES_DIR 由父进程导出
rm -rf "$HOME/.config/tmux"
ln -sfn "$DOTFILES_DIR/tmux" "$HOME/.config/tmux"
printf "  \033[36m%-24s\033[0m \033[2m→\033[0m \033[2;3m%s\033[0m\n" "~/.config/tmux/" "tmux/"
