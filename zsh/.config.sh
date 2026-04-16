#!/bin/bash
# zsh 配置链接 — 由 install.sh 调用，DOTFILES_DIR 由父进程导出

# ~/.config/zsh 目录链接
rm -rf "$HOME/.config/zsh"
ln -sfn "$DOTFILES_DIR/zsh" "$HOME/.config/zsh"
echo "  zsh -> ~/.config/zsh"

# 根级 symlink：~/.zshrc 和 ~/.zimrc
rm -f "$HOME/.zshrc" "$HOME/.zimrc"
ln -sfn "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"
ln -sfn "$DOTFILES_DIR/zsh/zimrc" "$HOME/.zimrc"
echo "  ~/.zshrc -> ~/.config/zsh/zshrc"
echo "  ~/.zimrc -> ~/.config/zsh/zimrc"

# 预下载 zimfw
ZIM_HOME="$DOTFILES_DIR/zsh/zim"
if [[ ! -e "$ZIM_HOME/zimfw.zsh" ]]; then
  echo "  下载 zimfw..."
  mkdir -p "$ZIM_HOME"
  curl -fsSL -o "$ZIM_HOME/zimfw.zsh" \
    https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi
