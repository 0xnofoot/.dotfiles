#!/bin/bash
set -e
: "${DOTFILES_DIR:?must be set by install.sh}"
# claude 配置链接 — 由 install.sh 调用，DOTFILES_DIR 由父进程导出
# 逐文件链接到 ~/.claude，保留运行时数据（历史记录、缓存等）

CLAUDE_DST="$HOME/.claude"
mkdir -p "$CLAUDE_DST"

# 受管条目：CLAUDE.md  settings.json  commands/ skills/ hooks/ on-demand/
MANAGED=(CLAUDE.md settings.json commands skills hooks on-demand)

for item in "${MANAGED[@]}"; do
  src="$DOTFILES_DIR/claude/$item"
  dst="$CLAUDE_DST/$item"

  [[ ! -e "$src" ]] && continue

  [[ -d "$src" ]] && suffix="/" || suffix=""
  rm -rf "$dst"
  ln -sfn "$src" "$dst"
  printf "  \033[36m%-25s\033[0m \033[2m→\033[0m \033[2;3mclaude/%s\033[0m\n" \
    "~/.claude/${item}${suffix}" "${item}${suffix}"
done

# ── codebase-memory-mcp 安装 ───────────────────────────────
# 269MB 编译二进制，不入库；官方 install.sh 从 GitHub release 按 OS/arch 下载到
# ~/.local/bin（含 checksum 校验、macOS 重签名）。用 --skip-config 跳过官方的
# "配置 agent" 步骤——那步会重写 cbm-* hooks 与注册 MCP，而 cbm hooks 已由本仓库
# claude/hooks/ + settings.json 管理（软链），让官方写会写穿污染仓库。MCP 改用
# claude mcp add --scope user 显式注册（写 ~/.claude.json 顶层，与本机现状一致）。
# 尽力而为：网络/claude 缺失则跳过，绝不让 install.sh 中断。
install_codebase_memory_mcp() {
  local bin="$HOME/.local/bin/codebase-memory-mcp"
  if [[ -x "$bin" ]] && "$bin" --version >/dev/null 2>&1; then
    printf "  \033[2mcodebase-memory-mcp 已安装：%s\033[0m\n" "$("$bin" --version 2>&1 | head -1)"
  else
    printf "  \033[2m下载 codebase-memory-mcp（约 269MB）...\033[0m\n"
    curl -fsSL https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh \
      | bash -s -- --skip-config \
      || { printf "  \033[2mcodebase-memory-mcp 下载失败，跳过\033[0m\n"; return 0; }
  fi
  command -v claude >/dev/null 2>&1 || {
    printf "  \033[2mclaude CLI 未安装，跳过 MCP 注册\033[0m\n"; return 0; }
  if claude mcp get codebase-memory-mcp >/dev/null 2>&1; then
    printf "  \033[2mMCP codebase-memory-mcp 已注册\033[0m\n"
  else
    claude mcp add --scope user codebase-memory-mcp "$bin" >/dev/null 2>&1 \
      && printf "  \033[2mMCP + codebase-memory-mcp\033[0m\n" \
      || printf "  \033[2mMCP 注册失败（手动：claude mcp add --scope user codebase-memory-mcp %s）\033[0m\n" "$bin"
  fi
}
install_codebase_memory_mcp || true

# ── Claude plugin 同步 ─────────────────────────────────────
# settings.json 是单一真相源（extraKnownMarketplaces + enabledPlugins）。
# installed_plugins.json 与 plugins/cache/ 不入库，由 `claude plugin` CLI 在本机重建。
# 尽力而为：缺 claude/jq 则跳过，逐条容错，绝不让 install.sh 中断。
sync_claude_plugins() {
  local settings="$DOTFILES_DIR/claude/settings.json"
  [[ -f "$settings" ]] || return 0
  if ! command -v claude >/dev/null 2>&1; then
    printf "  \033[2mclaude CLI 未安装，跳过 plugin 同步\033[0m\n"; return 0
  fi
  if ! command -v jq >/dev/null 2>&1; then
    printf "  \033[2mjq 未安装，跳过 plugin 同步\033[0m\n"; return 0
  fi

  # 1. 注册第三方 marketplace（内置官方源不在此列，install 时自动解析）
  while read -r repo; do
    [[ -n "$repo" ]] || continue
    claude plugin marketplace add "$repo" >/dev/null 2>&1 \
      && printf "  \033[2mmarketplace + %s\033[0m\n" "$repo" \
      || printf "  \033[2mmarketplace ~ %s（已存在或失败）\033[0m\n" "$repo"
  done < <(jq -r '.extraKnownMarketplaces // {} | to_entries[] | select(.value.source.source=="github") | .value.source.repo' "$settings")

  # 2. 安装声明的插件；value=false 的装后置为 disabled
  while IFS=$'\t' read -r plugin enabled; do
    [[ -n "$plugin" ]] || continue
    claude plugin install "$plugin" --scope user >/dev/null 2>&1 \
      && printf "  \033[2mplugin   + %s\033[0m\n" "$plugin" \
      || printf "  \033[2mplugin   ~ %s（已装或失败）\033[0m\n" "$plugin"
    [[ "$enabled" == "false" ]] && claude plugin disable "$plugin" >/dev/null 2>&1 || true
  done < <(jq -r '.enabledPlugins // {} | to_entries[] | "\(.key)\t\(.value)"' "$settings")
}
sync_claude_plugins || true
