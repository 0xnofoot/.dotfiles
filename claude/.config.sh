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
  #    github 源传 repo（owner/name），git 源传 url（如 GitLab SSH），二者均可被
  #    `claude plugin marketplace add` 当作 clone 目标处理。
  while read -r src; do
    [[ -n "$src" ]] || continue
    claude plugin marketplace add "$src" >/dev/null 2>&1 \
      && printf "  \033[2mmarketplace + %s\033[0m\n" "$src" \
      || printf "  \033[2mmarketplace ~ %s（已存在或失败）\033[0m\n" "$src"
  done < <(jq -r '.extraKnownMarketplaces // {} | to_entries[] | .value.source | if .source=="github" then .repo elif .source=="git" then .url else empty end' "$settings")

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
