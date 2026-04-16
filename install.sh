#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
export DOTFILES_DIR

# 解析命令行参数
INSTALL_KITTY=""
for arg in "$@"; do
  case "$arg" in
    --with-kitty) INSTALL_KITTY=yes ;;
  esac
done

info()    { printf "\033[1;34m==>\033[0m \033[1m%s\033[0m\n" "$1"; }
success() { printf "\033[1;32m==>\033[0m \033[1m%s\033[0m\n" "$1"; }
warn()    { printf "\033[1;33m==>\033[0m \033[1m%s\033[0m\n" "$1"; }
error()   { printf "\033[1;31m==>\033[0m \033[1m%s\033[0m\n" "$1"; exit 1; }

# ── Step 1/8: Linux 编译工具 ───────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
  info "Step 1/8: 安装 Linux 编译工具..."
  if command -v apt-get &>/dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y build-essential procps curl file git
  elif command -v dnf &>/dev/null; then
    sudo dnf groupinstall -y 'Development Tools'
    sudo dnf install -y procps-ng curl file git
  elif command -v pacman &>/dev/null; then
    sudo pacman -Sy --noconfirm base-devel procps-ng curl file git
  else
    warn "未知包管理器，请确保已安装编译工具（gcc, make, curl, git）"
  fi
  success "编译工具就绪"
else
  success "Step 1/8: macOS 编译工具（Xcode CLT）已就绪"
fi

# ── Step 2/8: Homebrew ────────────────────────────────────
info "Step 2/8: 安装 Homebrew..."
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 确保 brew 在当前会话的 PATH 中
if [[ "$(uname)" == "Darwin" ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    error "Homebrew 已安装但未找到（/opt/homebrew 或 /usr/local）"
  fi
else
  if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  else
    error "Homebrew 已安装但未找到（/home/linuxbrew/.linuxbrew）"
  fi
fi
success "Homebrew 就绪"

# ── Step 3/8: 安装依赖包 ──────────────────────────────────
info "Step 3/8: 通过 Brewfile 安装依赖包..."
brew bundle --file="$DOTFILES_DIR/Brewfile"
success "所有依赖包已安装"

# ── Step 4/8: kitty（仅 --with-kitty 时安装）──────────────
if [[ "$INSTALL_KITTY" == "yes" ]]; then
  if command -v kitty &>/dev/null; then
    success "Step 4/8: kitty 已安装，跳过"
  elif [[ "$(uname)" == "Darwin" ]]; then
    info "Step 4/8: 通过 Homebrew 安装 kitty..."
    brew install --cask kitty
    success "kitty 已安装"
  else
    info "Step 4/8: 通过官方脚本安装 kitty (Linux)..."
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
    mkdir -p ~/.local/bin
    ln -sfn ~/.local/kitty.app/bin/kitty ~/.local/bin/kitty
    ln -sfn ~/.local/kitty.app/bin/kitten ~/.local/bin/kitten
    success "kitty 已安装"
  fi
else
  success "Step 4/8: 跳过 kitty 安装"
fi

# ── Step 5/8: 链接配置 ────────────────────────────────────
info "Step 5/8: 链接配置..."
mkdir -p "$HOME/.config"
for script in "$DOTFILES_DIR"/*/.config.sh; do
  [[ -f "$script" ]] || continue
  pkg=$(basename "$(dirname "$script")")
  bash "$script" || error "$pkg 配置失败"
  printf "  \033[1;32m✓\033[0m \033[1m%s\033[0m\n" "$pkg"
done

git -C "$DOTFILES_DIR" config core.hooksPath .githooks
printf "  \033[36m%-24s\033[0m \033[2m→\033[0m \033[2;3m%s\033[0m\n" "dotfiles git hooks" ".githooks/"
success "所有配置已链接"

# ── Step 6/8: vscode / cursor 扩展 ───────────────────────
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

VSCODE_EXT_DIR="$DOTFILES_DIR/vscode"
_has_code=false
_has_cursor=false
command -v code   &>/dev/null && _has_code=true
command -v cursor &>/dev/null && _has_cursor=true

if ! $_has_code && ! $_has_cursor; then
  info "Step 6/8: 跳过扩展安装（未检测到 code / cursor CLI）"
else
  info "Step 6/8: 安装 vscode / cursor 扩展..."
  if $_has_code; then
    printf "  \033[33m%s\033[0m\n" "安装 Code 扩展..."
    install_extensions "code" "$VSCODE_EXT_DIR/extensions.txt"
    install_extensions "code" "$VSCODE_EXT_DIR/extensions-code.txt"
    printf "  \033[2m%s\033[0m\n" "Code 扩展安装完成"
  fi
  if $_has_cursor; then
    printf "  \033[33m%s\033[0m\n" "安装 Cursor 扩展..."
    install_extensions "cursor" "$VSCODE_EXT_DIR/extensions.txt"
    install_extensions "cursor" "$VSCODE_EXT_DIR/extensions-cursor.txt"
    printf "  \033[2m%s\033[0m\n" "Cursor 扩展安装完成"
  fi
  success "vscode / cursor 扩展安装完成"
fi

# ── Step 7/8: 默认 shell ──────────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
  info "Step 7/8: 设置默认 shell 为 zsh..."
  ZSH_PATH="$(which zsh)"
  if [[ "$SHELL" != "$ZSH_PATH" ]]; then
    if ! grep -qF "$ZSH_PATH" /etc/shells; then
      echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi
    chsh -s "$ZSH_PATH"
    success "默认 shell 已设置为 zsh"
  else
    success "默认 shell 已是 zsh"
  fi
else
  success "Step 7/8: macOS 默认 shell 已是 zsh"
fi

# ── Step 8/8: Nerd Fonts ──────────────────────────────────
info "Step 8/8: 安装 Nerd Fonts..."
FONT_DIR=""
if [[ "$(uname)" == "Darwin" ]]; then
  FONT_DIR="$HOME/Library/Fonts"
else
  FONT_DIR="$HOME/.local/share/fonts"
fi
mkdir -p "$FONT_DIR"

install_nerd_font() {
  local name="$1" zip_name="$2"
  if ls "$FONT_DIR"/*"$name"* &>/dev/null; then
    printf "  \033[2m%s 已安装\033[0m\n" "$name"
    return
  fi
  printf "  \033[33m下载 %s...\033[0m\n" "$name"
  local tmpdir
  tmpdir=$(mktemp -d)
  curl -fsSL -o "$tmpdir/$zip_name" \
    "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$zip_name"
  unzip -qo "$tmpdir/$zip_name" -d "$FONT_DIR" '*.ttf' '*.otf' 2>/dev/null || true
  rm -rf "$tmpdir"
}

install_nerd_font "FiraMono" "FiraMono.zip"
install_nerd_font "NerdFontsSymbolsOnly" "NerdFontsSymbolsOnly.zip"

# 在 Linux 上刷新字体缓存
if [[ "$(uname)" != "Darwin" ]]; then
  fc-cache -f "$FONT_DIR" 2>/dev/null || true
fi
success "Nerd Fonts 已安装"

echo ""
success "全部完成！重启终端以生效。"
