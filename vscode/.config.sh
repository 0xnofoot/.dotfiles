#!/bin/bash
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

for dir in "${VSCODE_DIRS[@]}"; do
  [[ ! -d "$dir" ]] && continue
  for f in "${VSCODE_FILES[@]}"; do
    rm -rf "$dir/$f"
    ln -sfn "$DOTFILES_DIR/vscode/$f" "$dir/$f"
  done
  echo "  $(basename "$(dirname "$dir")")/User -> vscode/"
done
