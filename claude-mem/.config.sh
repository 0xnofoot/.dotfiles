#!/bin/bash
set -e
: "${DOTFILES_DIR:?must be set by install.sh}"
# claude-mem 配置链接 — 由 install.sh 调用，DOTFILES_DIR 由父进程导出
# 只软链 settings.json 这一个配置文件到 ~/.claude-mem，其余全是运行时数据
# （claude-mem.db / chroma / logs / observer-sessions / *.pid 等）保留在
# ~/.claude-mem 真实目录中，不进入仓库。

CLAUDE_MEM_DST="$HOME/.claude-mem"
mkdir -p "$CLAUDE_MEM_DST"

src="$DOTFILES_DIR/claude-mem/settings.json"
dst="$CLAUDE_MEM_DST/settings.json"

if [[ -f "$src" ]]; then
  rm -rf "$dst"
  ln -sfn "$src" "$dst"
  printf "  \033[36m%-25s\033[0m \033[2m→\033[0m \033[2;3mclaude-mem/%s\033[0m\n" \
    "~/.claude-mem/settings.json" "settings.json"
fi
