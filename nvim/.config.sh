#!/bin/bash
set -e
# nvim 配置链接 — 由 install.sh 调用，DOTFILES_DIR 由父进程导出
rm -rf "$HOME/.config/nvim"
ln -sfn "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
echo "  ~/.config/nvim/          -> nvim/"
