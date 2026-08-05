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

# 找根 + 所有子仓（含 .git 目录，限深 4 层以覆盖 melos/.repo_cache 嵌套子仓，排除纯依赖）
# 用 while read 逐行读入数组，兼容 macOS 自带 bash 3.2（不支持 bash 4.0+ 的 mapfile）
# 注：限深 3 层会漏掉 flutter(melos workspace) 下 .repo_cache/<包>/.git 这类第 4 层子仓
repos=()
while IFS= read -r line; do
  [ -n "$line" ] && repos+=("$line")
done < <(find . -maxdepth 4 -name ".git" -type d 2>/dev/null \
  | grep -vE "node_modules|/Pods|/build|\.pub-cache|/dist|/vendor|/\.gradle|/\.dart_tool|/DerivedData" \
  | sed 's|/.git||' | sort -u)

[ "${#repos[@]}" -eq 0 ] && { echo "未找到 .git 仓库"; exit 0; }

# 大仓判定阈值：源码文件数超过此值的仓走后台并行，否则前台串行。
# 按规模动态判定，避免硬编码目录名（melos/.repo_cache 下的包名各异，无法靠模式匹配覆盖）
BIG_THRESHOLD=800
declare -a pids=()
declare -a pid_repos=()

for repo in "${repos[@]}"; do
  [ -d "$repo" ] || continue

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

  # 估算源码规模以决定是否并行（sync 也可能耗时，统一按规模判定）
  src_count=$(find "$repo" -type f \( -name "*.kt" -o -name "*.java" -o -name "*.swift" \
    -o -name "*.m" -o -name "*.mm" -o -name "*.h" -o -name "*.cpp" -o -name "*.cc" \
    -o -name "*.c" -o -name "*.dart" -o -name "*.py" -o -name "*.ts" -o -name "*.js" \) 2>/dev/null \
    | grep -vE "node_modules|/Pods/|/build/|/\.gradle/|/\.dart_tool/|/DerivedData/|/vendor/|/dist/" \
    | wc -l | tr -d ' ')
  is_big=0
  [ "${src_count:-0}" -ge "$BIG_THRESHOLD" ] && is_big=1

  if [ "$PARALLEL" = 1 ] && [ "$is_big" = 1 ]; then
    echo "→ $repo — $action (${src_count}源文件, 后台并行)..."
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
  fresh=$(echo "$st" | grep -qi "up to date" && echo "✓up-to-date" || echo "⚠stale")
  echo "$repo | $f | $n | $fresh"
done
