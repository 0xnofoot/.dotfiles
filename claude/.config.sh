#!/bin/bash
# claude 配置链接 — 由 install.sh 调用，DOTFILES_DIR 由父进程导出
# 逐文件链接到 ~/.claude，保留运行时数据（历史记录、缓存等）

CLAUDE_DST="$HOME/.claude"
mkdir -p "$CLAUDE_DST"

# 受管条目：CLAUDE.md  settings.json  commands/
MANAGED=(CLAUDE.md settings.json commands)

for item in "${MANAGED[@]}"; do
  src="$DOTFILES_DIR/claude/$item"
  dst="$CLAUDE_DST/$item"

  [[ ! -e "$src" ]] && continue

  [[ -d "$src" ]] && suffix="/" || suffix=""
  rm -rf "$dst"
  ln -sfn "$src" "$dst"
  printf "  %-25s -> claude/%s\n" "~/.claude/${item}${suffix}" "${item}${suffix}"
done
