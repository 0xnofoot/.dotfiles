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
    printf "  %-25s -> vscode/%s\n" "$app/User/$f" "$f"
  done
  linked=$((linked + 1))
done

[[ $linked -eq 0 ]] && echo "  未检测到已安装的编辑器，已跳过"
