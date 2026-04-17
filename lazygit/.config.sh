#!/bin/bash
set -e
: "${DOTFILES_DIR:?must be set by install.sh}"
# lazygit 依赖 XDG_CONFIG_HOME（由 zsh/env.zsh 导出为 ~/.config），
# macOS 与 Linux 统一链接到 ~/.config/lazygit
TARGET="$HOME/.config/lazygit"
mkdir -p "$(dirname "$TARGET")"
rm -rf "$TARGET"
ln -sfn "$DOTFILES_DIR/lazygit" "$TARGET"
printf "  \033[36m%-40s\033[0m \033[2m→\033[0m \033[2;3m%s\033[0m\n" "${TARGET/#$HOME/~}/" "lazygit/"
