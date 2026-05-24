#!/bin/bash
set -e
: "${DOTFILES_DIR:?must be set by install.sh}"
# JetBrains 系 IDE keymap 链接 — 由 install.sh 调用
# 不管 options/keymap.xml(避免和 IDE 自身的写入打架),用户首次启动后到
# Settings > Keymap 手动切到 Custom 即可

warn() { printf "\033[1;33m==>\033[0m \033[1m%s\033[0m\n" "$1"; }

JB_SRC="$DOTFILES_DIR/jetbrains"
KEYMAP_FILE="Custom.xml"

# ── ~/.ideavimrc 根级 symlink(IdeaVim 不走 XDG,所有 JetBrains 系 IDE 共用) ──
rm -f "$HOME/.ideavimrc"
ln -sfn "$JB_SRC/ideavimrc" "$HOME/.ideavimrc"
printf "  \033[36m%-44s\033[0m \033[2m→\033[0m \033[2;3mjetbrains/ideavimrc\033[0m\n" "~/.ideavimrc"

if [[ "$(uname)" == "Darwin" ]]; then
  JB_BASES=(
    "$HOME/Library/Application Support/JetBrains"
    "$HOME/Library/Application Support/Google"
  )
else
  JB_BASES=(
    "$HOME/.config/JetBrains"
    "$HOME/.config/Google"
  )
fi

# 已知 JetBrains 系 IDE 目录前缀(版本号会在每年大版本变,只用前缀匹配)
is_ide_dir() {
  case "$1" in
    AndroidStudio*|IntelliJIdea*|IdeaIC*|PyCharm*|WebStorm*|GoLand*|\
    Rider*|CLion*|RubyMine*|DataGrip*|PhpStorm*|AppCode*|Aqua*|\
    RustRover*|DataSpell*|Writerside*|Fleet*) return 0 ;;
    *) return 1 ;;
  esac
}

linked=0
for base in "${JB_BASES[@]}"; do
  [[ -d "$base" ]] || continue
  for product_dir in "$base"/*/; do
    [[ -d "$product_dir" ]] || continue
    product_name=$(basename "$product_dir")
    is_ide_dir "$product_name" || continue

    keymap_target_dir="${product_dir%/}/keymaps"
    mkdir -p "$keymap_target_dir"
    target="$keymap_target_dir/$KEYMAP_FILE"
    rm -rf "$target"
    ln -sfn "$JB_SRC/keymaps/$KEYMAP_FILE" "$target"
    printf "  \033[36m%-44s\033[0m \033[2m→\033[0m \033[2;3mjetbrains/keymaps/%s\033[0m\n" \
      "$product_name/keymaps/$KEYMAP_FILE" "$KEYMAP_FILE"
    linked=$((linked + 1))
  done
done

if [[ $linked -eq 0 ]]; then
  printf "  \033[33m%s\033[0m\n" "未检测到 JetBrains 系 IDE,已跳过 keymap 链接(ideavimrc 已链)"
fi

# 插件提示(JetBrains 没有稳定 CLI,只能在 IDE 内 Marketplace 装)
plugins_file="$JB_SRC/plugins.txt"
if [[ $linked -gt 0 && -f "$plugins_file" ]]; then
  plugin_lines=()
  while IFS= read -r line; do
    line=$(echo "$line" | sed 's/#.*//' | xargs)
    [[ -z "$line" ]] && continue
    plugin_lines+=("$line")
  done < "$plugins_file"
  if [[ ${#plugin_lines[@]} -gt 0 ]]; then
    printf "\n  \033[33m%s\033[0m\n" "请在 IDE 内 Marketplace 安装以下插件:"
    for p in "${plugin_lines[@]}"; do
      printf "    \033[2m- %s\033[0m\n" "$p"
    done
    printf "  \033[2m%s\033[0m\n" "装好后:Settings > Keymap > Custom"
  fi
fi
