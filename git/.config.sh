#!/bin/bash
set -e
: "${DOTFILES_DIR:?must be set by install.sh}"
# git 片段接入 — 不走 symlink，通过 include.path 合并到 ~/.gitconfig
# 这样用户 ~/.gitconfig 的私有信息（邮箱、URL rewrites 等）不必入库。
TARGET="$DOTFILES_DIR/git/common.gitconfig"
if ! git config --global --get-all include.path 2>/dev/null | grep -qxF "$TARGET"; then
  git config --global --add include.path "$TARGET"
fi
printf "  \033[36m%-24s\033[0m \033[2m←\033[0m \033[2;3m%s\033[0m\n" "~/.gitconfig [include]" "git/common.gitconfig"
