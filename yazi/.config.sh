#!/bin/bash
# yazi 配置链接 — 由 install.sh 调用，DOTFILES_DIR 由父进程导出
rm -rf "$HOME/.config/yazi"
ln -sfn "$DOTFILES_DIR/yazi" "$HOME/.config/yazi"
echo "  ~/.config/yazi/          -> yazi/"
