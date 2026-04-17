#!/bin/bash
set -e
: "${DOTFILES_DIR:?must be set by install.sh}"
# vscode / cursor 配置链接与扩展安装 — 由 install.sh 调用，DOTFILES_DIR 由父进程导出

warn() { printf "\033[1;33m==>\033[0m \033[1m%s\033[0m\n" "$1"; }

VSCODE_SRC="$DOTFILES_DIR/vscode"
VSCODE_FILES=(settings.json keybindings.json)

# ── 链接配置文件 ──

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
    ln -sfn "$VSCODE_SRC/$f" "$dir/$f"
    printf "  \033[36m%-30s\033[0m \033[2m→\033[0m \033[2;3mvscode/%s\033[0m\n" "$app/User/$f" "$f"
  done
  linked=$((linked + 1))
done

if [[ $linked -eq 0 ]]; then
  printf "  \033[33m%s\033[0m\n" "未检测到已安装的编辑器，已跳过"
fi

# ── 安装扩展 ──

install_extensions() {
  local cli="$1" file="$2"
  [[ ! -f "$file" ]] && return
  local installed
  installed=$("$cli" --list-extensions 2>/dev/null) || return
  while IFS= read -r ext; do
    ext=$(echo "$ext" | sed 's/#.*//' | xargs)
    [[ -z "$ext" ]] && continue
    echo "$installed" | grep -qiF "$ext" && continue
    printf "    \033[2m安装 %s\033[0m\n" "$ext"
    "$cli" --install-extension "$ext" --force 2>/dev/null || warn "    安装失败: $ext"
  done < "$file"
}

_has_code=false
_has_cursor=false
command -v code   &>/dev/null && _has_code=true
command -v cursor &>/dev/null && _has_cursor=true

if $_has_code || $_has_cursor; then
  if $_has_code; then
    printf "  \033[33m%s\033[0m\n" "安装 Code 扩展..."
    install_extensions "code" "$VSCODE_SRC/extensions/shared.txt"
    install_extensions "code" "$VSCODE_SRC/extensions/code.txt"
    printf "  \033[2m%s\033[0m\n" "Code 扩展安装完成"
  fi
  if $_has_cursor; then
    printf "  \033[33m%s\033[0m\n" "安装 Cursor 扩展..."
    install_extensions "cursor" "$VSCODE_SRC/extensions/shared.txt"
    install_extensions "cursor" "$VSCODE_SRC/extensions/cursor.txt"
    printf "  \033[2m%s\033[0m\n" "Cursor 扩展安装完成"
  fi
  # 提示需要本地安装的 VSIX 扩展
  vsix_file="$VSCODE_SRC/extensions/vsix.txt"
  if [[ -f "$vsix_file" ]]; then
    vsix_list=()
    while IFS= read -r ext; do
      ext=$(echo "$ext" | sed 's/#.*//' | xargs)
      [[ -z "$ext" ]] && continue
      vsix_list+=("$ext")
    done < "$vsix_file"
    if [[ ${#vsix_list[@]} -gt 0 ]]; then
      printf "\n  \033[33m%s\033[0m\n" "以下扩展需要通过 VSIX 本地安装："
      for ext in "${vsix_list[@]}"; do
        printf "    \033[2m- %s\033[0m\n" "$ext"
      done
      printf "  \033[2m%s\033[0m\n" "请手动下载 .vsix 文件后运行: code/cursor --install-extension <file>.vsix"
    fi
  fi
else
  printf "  \033[33m%s\033[0m\n" "未检测到 code / cursor CLI，跳过扩展安装"
fi
