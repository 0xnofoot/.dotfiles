#!/bin/bash
set -e
: "${DOTFILES_DIR:?must be set by install.sh}"
# karabiner 配置链接 — 仅 macOS（Karabiner-Elements 是 macOS 专属，Linux 跳过）
[[ "$(uname)" != "Darwin" ]] && exit 0
rm -rf "$HOME/.config/karabiner"
ln -sfn "$DOTFILES_DIR/karabiner" "$HOME/.config/karabiner"
printf "  \033[36m%-24s\033[0m \033[2m→\033[0m \033[2;3m%s\033[0m\n" "~/.config/karabiner/" "karabiner/"
