#!/bin/bash
set -e
: "${DOTFILES_DIR:?must be set by install.sh}"
# bottom (btm) 配置链接 — 由 install.sh 调用，DOTFILES_DIR 由父进程导出
rm -rf "$HOME/.config/bottom"
ln -sfn "$DOTFILES_DIR/bottom" "$HOME/.config/bottom"
printf "  \033[36m%-24s\033[0m \033[2m→\033[0m \033[2;3m%s\033[0m\n" "~/.config/bottom/" "bottom/"
