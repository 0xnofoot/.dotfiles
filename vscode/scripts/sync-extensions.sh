#!/bin/bash
#
# 同步 VSCode / Cursor 已安装扩展到扩展列表文件。
#
# 用法:
#   bash sync-extensions.sh          # 交互模式：报告差异并询问是否同步
#   bash sync-extensions.sh --check  # 检查模式：有差异时返回退出码 1（用于 git hook）
#

set -e

CHECK_MODE=false
[[ "${1:-}" == "--check" ]] && CHECK_MODE=true

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VSCODE_DIR="$(dirname "$SCRIPT_DIR")"

SHARED_FILE="$VSCODE_DIR/extensions.txt"
CODE_FILE="$VSCODE_DIR/extensions-code.txt"
CURSOR_FILE="$VSCODE_DIR/extensions-cursor.txt"

info()  { printf "\033[1;34m==>\033[0m \033[1m%s\033[0m\n" "$1"; }
warn()  { printf "\033[1;33m==>\033[0m \033[1m%s\033[0m\n" "$1"; }
ok()    { printf "\033[1;32m==>\033[0m \033[1m%s\033[0m\n" "$1"; }

# 从文件中提取扩展 ID（忽略注释和空行，统一小写）
parse_file() {
  local file="$1"
  [[ ! -f "$file" ]] && return
  sed 's/#.*//' "$file" | tr -d ' ' | tr '[:upper:]' '[:lower:]' | grep -v '^$'
}

# 获取已安装扩展（统一小写）
get_installed() {
  local cli="$1"
  "$cli" --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]' | sort -f
}

# 收集所有已跟踪的扩展 ID
all_tracked=$(mktemp)
{
  parse_file "$SHARED_FILE"
  parse_file "$CODE_FILE"
  parse_file "$CURSOR_FILE"
} | sort -u > "$all_tracked"

has_code=false
has_cursor=false
code_installed=$(mktemp)
cursor_installed=$(mktemp)

if command -v code &>/dev/null; then
  has_code=true
  get_installed "code" > "$code_installed"
  info "Code: $(wc -l < "$code_installed" | tr -d ' ') 个扩展已安装"
else
  warn "code CLI 未找到，跳过 Code"
fi

if command -v cursor &>/dev/null; then
  has_cursor=true
  get_installed "cursor" > "$cursor_installed"
  info "Cursor: $(wc -l < "$cursor_installed" | tr -d ' ') 个扩展已安装"
else
  warn "cursor CLI 未找到，跳过 Cursor"
fi

info "已跟踪: $(wc -l < "$all_tracked" | tr -d ' ') 个扩展"
echo ""

# 计算差异
new_shared=()    # 两者都有但未跟踪
new_code=()      # 仅 Code 有但未跟踪
new_cursor=()    # 仅 Cursor 有但未跟踪
removed=()       # 已跟踪但两者都没装

# 合并所有已安装的扩展
all_installed=$(mktemp)
cat "$code_installed" "$cursor_installed" | sort -u > "$all_installed"

# 找新增：已安装但未跟踪
while IFS= read -r ext; do
  [[ -z "$ext" ]] && continue
  if ! grep -qiF "$ext" "$all_tracked"; then
    in_code=false
    in_cursor=false
    $has_code && grep -qiF "$ext" "$code_installed" && in_code=true
    $has_cursor && grep -qiF "$ext" "$cursor_installed" && in_cursor=true

    if $in_code && $in_cursor; then
      new_shared+=("$ext")
    elif $in_code; then
      new_code+=("$ext")
    elif $in_cursor; then
      new_cursor+=("$ext")
    fi
  fi
done < "$all_installed"

# 找已移除：已跟踪但未安装
while IFS= read -r ext; do
  [[ -z "$ext" ]] && continue
  if ! grep -qiF "$ext" "$all_installed"; then
    removed+=("$ext")
  fi
done < "$all_tracked"

# 清理临时文件
cleanup() { rm -f "$all_tracked" "$code_installed" "$cursor_installed" "$all_installed"; }
trap cleanup EXIT

# 报告
new_count=$((${#new_shared[@]} + ${#new_code[@]} + ${#new_cursor[@]}))

if [[ $new_count -eq 0 && ${#removed[@]} -eq 0 ]]; then
  ok "扩展列表已是最新，无需同步"
  exit 0
fi

if [[ ${#new_shared[@]} -gt 0 ]]; then
  info "新增共享扩展（Code + Cursor 都有）:"
  for ext in "${new_shared[@]}"; do echo "  + $ext"; done
fi
if [[ ${#new_code[@]} -gt 0 ]]; then
  info "新增 Code 独有扩展:"
  for ext in "${new_code[@]}"; do echo "  + $ext"; done
fi
if [[ ${#new_cursor[@]} -gt 0 ]]; then
  info "新增 Cursor 独有扩展:"
  for ext in "${new_cursor[@]}"; do echo "  + $ext"; done
fi
if [[ ${#removed[@]} -gt 0 ]]; then
  warn "已跟踪但未安装（可能已卸载）:"
  for ext in "${removed[@]}"; do echo "  - $ext"; done
fi

# --check 模式：有差异时返回 1
if $CHECK_MODE; then
  if [[ $new_count -gt 0 ]]; then
    echo ""
    warn "扩展列表未同步，请先运行: bash vscode/scripts/sync-extensions.sh"
    exit 1
  fi
  exit 0
fi

# 交互模式
echo ""
printf "\033[1;34m==>\033[0m \033[1m是否将新增扩展追加到对应文件？(y/N) \033[0m"
read -r answer

if [[ "$answer" == [yY] ]]; then
  for ext in "${new_shared[@]}"; do
    echo "$ext" >> "$SHARED_FILE"
  done
  for ext in "${new_code[@]}"; do
    echo "$ext" >> "$CODE_FILE"
  done
  for ext in "${new_cursor[@]}"; do
    echo "$ext" >> "$CURSOR_FILE"
  done
  ok "已追加 $new_count 个新扩展"

  if [[ ${#removed[@]} -gt 0 ]]; then
    warn "已移除的扩展需要手动从文件中删除对应行"
  fi
else
  echo "  已跳过"
fi
