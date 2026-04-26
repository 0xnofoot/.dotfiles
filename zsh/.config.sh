#!/bin/bash
set -e
: "${DOTFILES_DIR:?must be set by install.sh}"
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

# ── 生成 en_US.UTF-8 locale ──
# zsh/env.zsh 导出 LANG/LC_ALL=en_US.UTF-8，远端 Linux 常只装 C/POSIX，
# locale 未生成时 zle 会退回 8-bit 模式导致中文输入显示成 <ff...>
# macOS 默认自带该 locale，这里只处理 Linux

if [[ "$(uname)" != "Darwin" ]]; then
  if ! locale -a 2>/dev/null | grep -qiE '^en_US\.?utf-?8$'; then
    printf "  \033[33m%s\033[0m\n" "生成 en_US.UTF-8 locale..."
    if command -v locale-gen &>/dev/null; then
      # Debian/Ubuntu：先在 /etc/locale.gen 取消注释再生成，同时写 update-locale
      sudo sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen 2>/dev/null || true
      sudo locale-gen en_US.UTF-8
      sudo update-locale LANG=en_US.UTF-8 2>/dev/null || true
    elif command -v localedef &>/dev/null; then
      # Fedora/Arch/Alpine 等非 Debian 系 glibc
      sudo localedef -i en_US -f UTF-8 en_US.UTF-8
    else
      printf "  \033[31m%s\033[0m\n" "未找到 locale-gen/localedef，需手动生成 en_US.UTF-8"
    fi
  fi
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
