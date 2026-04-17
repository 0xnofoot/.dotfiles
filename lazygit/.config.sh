#!/bin/bash
set -e
# lazygit 配置链接 — macOS 与 Linux 路径不同，按平台处理
if [[ "$(uname)" == "Darwin" ]]; then
  TARGET="$HOME/Library/Application Support/lazygit"
else
  TARGET="$HOME/.config/lazygit"
fi
mkdir -p "$(dirname "$TARGET")"
rm -rf "$TARGET"
ln -sfn "$DOTFILES_DIR/lazygit" "$TARGET"
printf "  \033[36m%-40s\033[0m \033[2m→\033[0m \033[2;3m%s\033[0m\n" "${TARGET/#$HOME/~}/" "lazygit/"
