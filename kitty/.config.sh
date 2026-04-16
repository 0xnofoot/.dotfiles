#!/bin/bash
set -e
# kitty 配置链接 — 由 install.sh 调用，DOTFILES_DIR 由父进程导出
rm -rf "$HOME/.config/kitty"
ln -sfn "$DOTFILES_DIR/kitty" "$HOME/.config/kitty"
echo "  ~/.config/kitty/         -> kitty/"
