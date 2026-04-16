#!/bin/bash
set -e
# kitty 配置链接 — 由 install.sh 调用，DOTFILES_DIR 由父进程导出
rm -rf "$HOME/.config/kitty"
ln -sfn "$DOTFILES_DIR/kitty" "$HOME/.config/kitty"
printf "  \033[36m%-24s\033[0m \033[2m→\033[0m \033[2;3m%s\033[0m\n" "~/.config/kitty/" "kitty/"
