#!/bin/bash
set -e
# vscode / cursor 配置链接 — 由 install.sh 调用，DOTFILES_DIR 由父进程导出

VSCODE_FILES=(settings.json keybindings.json)

if [[ "$(uname)" == "Darwin" ]]; then
  VSCODE_DIRS=(
    "$HOME/Library/Application Support/Code/User"
    "$HOME/Library/Application Support/Cursor/User"
  )
else
  VSCODE_DIRS=(
    "$HOME/.config/Code/User"
    "$HOME/.config/Cursor/User"
  )
fi

linked=0
for dir in "${VSCODE_DIRS[@]}"; do
  [[ ! -d "$dir" ]] && continue
  app=$(basename "$(dirname "$dir")")
  for f in "${VSCODE_FILES[@]}"; do
    rm -rf "$dir/$f"
    ln -sfn "$DOTFILES_DIR/vscode/$f" "$dir/$f"
    printf "  \033[36m%-30s\033[0m \033[2m→\033[0m \033[2;3mvscode/%s\033[0m\n" "$app/User/$f" "$f"
  done
  linked=$((linked + 1))
done

if [[ $linked -eq 0 ]]; then
  printf "  \033[33m%s\033[0m\n" "未检测到已安装的编辑器，已跳过"
fi
