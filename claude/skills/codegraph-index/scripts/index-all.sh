#!/usr/bin/env bash
# codegraph 多仓索引驱动 — 扫根+子仓，跳过已新鲜，init/sync 其余。
# 用法: index-all.sh [根目录] [--parallel]
# 大仓库(android/ios/flutter)默认串行；--parallel 时大仓后台并行(各起一进程)。
set -uo pipefail
export PATH="/opt/homebrew/bin:$PATH"

ROOT="$PWD"
PARALLEL=0
for arg in "$@"; do
  case "$arg" in
    --parallel) PARALLEL=1 ;;
    *) ROOT="$arg" ;;
  esac
done

command -v codegraph >/dev/null 2>&1 || { echo "ERR: codegraph CLI 未装。npm i -g @colbymchenry/codegraph"; exit 1; }

cd "$ROOT" || { echo "ERR: 无法 cd 到 $ROOT"; exit 1; }
echo "=== codegraph 多仓索引 | 根: $ROOT | parallel=$PARALLEL ==="

# 找根 + 所有子仓（含 .git 目录，限深 3 层，排除纯依赖）
mapfile -t repos < <(find . -maxdepth 3 -name ".git" -type d 2>/dev/null \
  | grep -vE "node_modules|/Pods|/build|\.pub-cache|/dist|/vendor|/\.gradle|/\.dart_tool|/DerivedData" \
  | sed 's|/.git||' | sort -u)

[ "${#repos[@]}" -eq 0 ] && { echo "未找到 .git 仓库"; exit 0; }

big_patterns=("android" "ios" "flutter")  # 预期大仓库（按目录名包含判定）
declare -a pids=()
declare -a pid_repos=()

for repo in "${repos[@]}"; do
  [ -d "$repo" ] || continue
  is_big=0
  for b in "${big_patterns[@]}"; do [[ "$repo" == *"$b"* ]] && is_big=1; done

  if [ -d "$repo/.codegraph" ]; then
    # 已索引，判 stale
    if (cd "$repo" && codegraph status 2>&1 | grep -q "up to date"); then
      echo "✓ $repo — up to date, skip"
      continue
    fi
    action="sync"
  else
    action="init"
  fi

  if [ "$PARALLEL" = 1 ] && [ "$is_big" = 1 ]; then
    echo "→ $repo — $action (后台并行)..."
    logf="/tmp/cg_${repo//\//_}.log"
    (cd "$repo" && codegraph "$action" >"$logf" 2>&1) &
    pids+=($!)
    pid_repos+=("$repo")
    echo "  PID $! → $logf"
  else
    echo "→ $repo — $action..."
    (cd "$repo" && codegraph "$action" 2>&1 | tail -3) || echo "  ⚠ $repo $action 失败，继续"
  fi
done

# 等后台
if [ "${#pids[@]}" -gt 0 ]; then
  echo "=== 等待后台任务: ${pids[*]} ==="
  for i in "${!pids[@]}"; do
    pid="${pids[$i]}"
    repo="${pid_repos[$i]}"
    if wait "$pid"; then
      echo "  ✓ $repo (PID $pid) done"
    else
      echo "  ⚠ $repo (PID $pid) FAIL — 见 /tmp/cg_${repo//\//_}.log"
    fi
  done
fi

echo "=== 汇总 ==="
for repo in "${repos[@]}"; do
  [ -d "$repo/.codegraph" ] || { echo "$repo | 未索引"; continue; }
  st=$(cd "$repo" && codegraph status 2>&1)
  f=$(echo "$st" | grep "Files:" | head -1 | tr -s ' ')
  n=$(echo "$st" | grep "Nodes:" | head -1 | tr -s ' ')
  echo "$repo | $f | $n"
done
