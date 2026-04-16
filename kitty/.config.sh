#!/bin/bash
set -e
# kitty 可选安装与配置链接 — 由 install.sh 调用，DOTFILES_DIR / INSTALL_KITTY 由父进程导出

# ── 可选安装 kitty（--with-kitty 时 INSTALL_KITTY=yes）──

if [[ "${INSTALL_KITTY:-}" == "yes" ]]; then
  if ! command -v kitty &>/dev/null; then
    if [[ "$(uname)" == "Darwin" ]]; then
      printf "  \033[33m%s\033[0m\n" "通过 Homebrew 安装 kitty..."
      brew install --cask kitty
    else
      printf "  \033[33m%s\033[0m\n" "通过官方脚本安装 kitty (Linux)..."
      curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
      mkdir -p ~/.local/bin
      ln -sfn ~/.local/kitty.app/bin/kitty ~/.local/bin/kitty
      ln -sfn ~/.local/kitty.app/bin/kitten ~/.local/bin/kitten
    fi
  fi
fi

# ── 链接配置 ──

rm -rf "$HOME/.config/kitty"
ln -sfn "$DOTFILES_DIR/kitty" "$HOME/.config/kitty"
printf "  \033[36m%-24s\033[0m \033[2m→\033[0m \033[2;3m%s\033[0m\n" "~/.config/kitty/" "kitty/"
