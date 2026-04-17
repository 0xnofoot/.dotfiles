#!/bin/bash
set -e
: "${DOTFILES_DIR:?must be set by install.sh}"
# svim 配置链接 — 由 install.sh 调用，DOTFILES_DIR 由父进程导出
rm -rf "$HOME/.config/svim"
ln -sfn "$DOTFILES_DIR/svim" "$HOME/.config/svim"
printf "  \033[36m%-24s\033[0m \033[2m→\033[0m \033[2;3m%s\033[0m\n" "~/.config/svim/" "svim/"
