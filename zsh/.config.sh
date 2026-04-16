#!/bin/bash
set -e
# zsh 配置链接与默认 shell 设置 — 由 install.sh 调用，DOTFILES_DIR 由父进程导出

# ── ~/.config/zsh 目录链接 ──

rm -rf "$HOME/.config/zsh"
ln -sfn "$DOTFILES_DIR/zsh" "$HOME/.config/zsh"
printf "  \033[36m%-24s\033[0m \033[2m→\033[0m \033[2;3m%s\033[0m\n" "~/.config/zsh/" "zsh/"

# 根级 symlink：~/.zshrc 和 ~/.zimrc
rm -f "$HOME/.zshrc" "$HOME/.zimrc"
ln -sfn "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"
ln -sfn "$DOTFILES_DIR/zsh/zimrc" "$HOME/.zimrc"
printf "  \033[36m%-24s\033[0m \033[2m→\033[0m \033[2;3m%s\033[0m\n" "~/.zshrc" "zsh/zshrc"
printf "  \033[36m%-24s\033[0m \033[2m→\033[0m \033[2;3m%s\033[0m\n" "~/.zimrc" "zsh/zimrc"

# 预下载 zimfw
ZIM_HOME="$DOTFILES_DIR/zsh/zim"
if [[ ! -e "$ZIM_HOME/zimfw.zsh" ]]; then
  printf "  \033[33m%s\033[0m\n" "下载 zimfw..."
  mkdir -p "$ZIM_HOME"
  curl -fsSL -o "$ZIM_HOME/zimfw.zsh" \
    https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi

# ── 设置默认 shell ──

if [[ "$(uname)" != "Darwin" ]]; then
  ZSH_PATH="$(which zsh)"
  if [[ "$SHELL" != "$ZSH_PATH" ]]; then
    if ! grep -qF "$ZSH_PATH" /etc/shells; then
      echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi
    chsh -s "$ZSH_PATH"
    printf "  \033[33m%s\033[0m\n" "默认 shell 已设置为 zsh"
  fi
fi
