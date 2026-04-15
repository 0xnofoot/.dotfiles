#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_PACKAGES=(kitty tmux nvim yazi zsh vscode)

# 解析命令行参数
INSTALL_KITTY=""
for arg in "$@"; do
  case "$arg" in
    --with-kitty) INSTALL_KITTY=yes ;;
    --no-kitty)   INSTALL_KITTY=no ;;
  esac
done

info()    { printf "\033[1;34m==>\033[0m \033[1m%s\033[0m\n" "$1"; }
success() { printf "\033[1;32m==>\033[0m \033[1m%s\033[0m\n" "$1"; }
warn()    { printf "\033[1;33m==>\033[0m \033[1m%s\033[0m\n" "$1"; }
error()   { printf "\033[1;31m==>\033[0m \033[1m%s\033[0m\n" "$1"; exit 1; }

# ── Step 1/9: Linux 编译工具 ──────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
  info "Step 1/9: 安装 Linux 编译工具..."
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
  success "Step 1/9: macOS 编译工具（Xcode CLT）已就绪"
fi

# ── Step 2/9: Homebrew ────────────────────────────────────
info "Step 2/9: 安装 Homebrew..."
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

# ── Step 3/9: 安装依赖包 ─────────────────────────────────
info "Step 3/9: 通过 Brewfile 安装依赖包..."
brew bundle --file="$DOTFILES_DIR/Brewfile"
success "所有依赖包已安装"

# ── Step 4/9: kitty（可选）───────────────────────────────
if [[ -z "$INSTALL_KITTY" ]]; then
  printf "\033[1;34m==>\033[0m \033[1m是否安装 kitty 终端？(y/N) \033[0m"
  read -r answer
  [[ "$answer" == [yY] ]] && INSTALL_KITTY=yes || INSTALL_KITTY=no
fi

if [[ "$INSTALL_KITTY" == "yes" ]]; then
  if command -v kitty &>/dev/null; then
    success "Step 4/9: kitty 已安装，跳过"
  elif [[ "$(uname)" == "Darwin" ]]; then
    info "Step 4/9: 通过 Homebrew 安装 kitty..."
    brew install --cask kitty
    success "kitty 已安装"
  else
    info "Step 4/9: 通过官方脚本安装 kitty (Linux)..."
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
    mkdir -p ~/.local/bin
    ln -sfn ~/.local/kitty.app/bin/kitty ~/.local/bin/kitty
    ln -sfn ~/.local/kitty.app/bin/kitten ~/.local/bin/kitten
    success "kitty 已安装"
  fi
else
  success "Step 4/9: 跳过 kitty 安装"
fi

# ── Step 5/9: 链接配置 ───────────────────────────────────
info "Step 5/9: 链接配置到 ~/.config/..."
mkdir -p "$HOME/.config"
for pkg in "${CONFIG_PACKAGES[@]}"; do
  ln -sfn "$DOTFILES_DIR/$pkg" "$HOME/.config/$pkg"
  echo "  $pkg -> ~/.config/$pkg"
done
success "所有配置已链接"

# ── Step 6/9: zsh 设置 ───────────────────────────────────
info "Step 6/9: 配置 zsh..."

# 备份已有的非符号链接文件
for f in "$HOME/.zshrc" "$HOME/.zimrc"; do
  if [[ -e "$f" && ! -L "$f" ]]; then
    warn "备份 $(basename "$f") 为 $(basename "$f").bak"
    mv "$f" "$f.bak"
  fi
done

ln -sfn "$HOME/.config/zsh/zshrc" "$HOME/.zshrc"
ln -sfn "$HOME/.config/zsh/zimrc" "$HOME/.zimrc"
echo "  ~/.zshrc -> ~/.config/zsh/zshrc"
echo "  ~/.zimrc -> ~/.config/zsh/zimrc"

# 预下载 zimfw
ZIM_HOME="$HOME/.config/zsh/zim"
if [[ ! -e "$ZIM_HOME/zimfw.zsh" ]]; then
  echo "  下载 zimfw..."
  mkdir -p "$ZIM_HOME"
  curl -fsSL -o "$ZIM_HOME/zimfw.zsh" \
    https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi
success "zsh 配置完成"

# ── Step 7/9: vscode / cursor ────────────────────────────
info "Step 7/9: 链接 vscode / cursor 配置..."
VSCODE_FILES=(settings.json keybindings.json)

if [[ "$(uname)" == "Darwin" ]]; then
  VSCODE_DIRS=(
    "$HOME/Library/Application Support/Code/User"
    "$HOME/Library/Application Support/Cursor/User"
  )
else
  VSCODE_DIRS=(
    "$HOME/.config/Code/User"
    "$HOME/.config/Cursor/User"
  )
fi

for dir in "${VSCODE_DIRS[@]}"; do
  if [[ ! -d "$dir" ]]; then
    echo "  $(basename "$(dirname "$dir")") 未找到，跳过"
    continue
  fi
  for f in "${VSCODE_FILES[@]}"; do
    if [[ -e "$dir/$f" && ! -L "$dir/$f" ]]; then
      warn "备份 $dir/$f 为 $dir/$f.bak"
      mv "$dir/$f" "$dir/$f.bak"
    fi
    ln -sfn "$HOME/.config/vscode/$f" "$dir/$f"
  done
  echo "  $(basename "$(dirname "$dir")")/User -> vscode/"
done
success "vscode / cursor 配置完成"

# ── Step 8/9: 默认 shell ─────────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
  info "Step 8/9: 设置默认 shell 为 zsh..."
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
  success "Step 8/9: macOS 默认 shell 已是 zsh"
fi

# ── Step 9/9: Nerd Fonts ─────────────────────────────────
info "Step 9/9: 安装 Nerd Fonts..."
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
    echo "  $name 已安装"
    return
  fi
  echo "  下载 $name..."
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
