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
export INSTALL_KITTY

info()    { printf "\033[1;34m==>\033[0m \033[1m%s\033[0m\n" "$1"; }
success() { printf "\033[1;32m==>\033[0m \033[1m%s\033[0m\n" "$1"; }
warn()    { printf "\033[1;33m==>\033[0m \033[1m%s\033[0m\n" "$1"; }
error()   { printf "\033[1;31m==>\033[0m \033[1m%s\033[0m\n" "$1"; exit 1; }

# ── Step 1/5: Linux 编译工具 ───────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
  info "Step 1/5: 安装 Linux 编译工具..."
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
  success "Step 1/5: macOS 编译工具（Xcode CLT）已就绪"
fi

# ── Step 2/5: Homebrew ────────────────────────────────────
info "Step 2/5: 安装 Homebrew..."
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

# ── Step 3/5: 安装依赖包 ──────────────────────────────────
info "Step 3/5: 通过 Brewfile 安装依赖包..."
brew bundle --file="$DOTFILES_DIR/Brewfile"
success "所有依赖包已安装"

# ── Step 4/5: 链接配置 ────────────────────────────────────
info "Step 4/5: 链接配置..."
mkdir -p "$HOME/.config"
for script in "$DOTFILES_DIR"/*/.config.sh; do
  [[ -f "$script" ]] || continue
  pkg=$(basename "$(dirname "$script")")
  bash "$script" || error "$pkg 配置失败"
  printf "  \033[1;32m✓\033[0m \033[1m%s\033[0m\n" "$pkg"
done

git -C "$DOTFILES_DIR" config core.hooksPath .githooks
printf "  \033[2mgit config core.hooksPath\033[0m \033[2m=\033[0m \033[2;3m.githooks/\033[0m\n"
success "所有配置已链接"

# ── Step 5/5: Nerd Fonts ──────────────────────────────────
info "Step 5/5: 安装 Nerd Fonts..."
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
