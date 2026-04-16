#!/bin/bash
# tmux 配置链接 — 由 install.sh 调用，DOTFILES_DIR 由父进程导出
rm -rf "$HOME/.config/tmux"
ln -sfn "$DOTFILES_DIR/tmux" "$HOME/.config/tmux"
echo "  ~/.config/tmux/          -> tmux/"
