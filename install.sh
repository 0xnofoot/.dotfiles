#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_PACKAGES=(kitty tmux nvim yazi zsh vscode)

info()    { printf "\033[1;34m==>\033[0m \033[1m%s\033[0m\n" "$1"; }
success() { printf "\033[1;32m==>\033[0m \033[1m%s\033[0m\n" "$1"; }
warn()    { printf "\033[1;33m==>\033[0m \033[1m%s\033[0m\n" "$1"; }
error()   { printf "\033[1;31m==>\033[0m \033[1m%s\033[0m\n" "$1"; exit 1; }

# ── Step 1/9: Linux build tools ───────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
  info "Step 1/9: Installing Linux build tools..."
  if command -v apt-get &>/dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y build-essential procps curl file git
  elif command -v dnf &>/dev/null; then
    sudo dnf groupinstall -y 'Development Tools'
    sudo dnf install -y procps-ng curl file git
  elif command -v pacman &>/dev/null; then
    sudo pacman -Sy --noconfirm base-devel procps-ng curl file git
  else
    warn "Unknown package manager, please ensure build tools (gcc, make, curl, git) are installed"
  fi
  success "Build tools ready"
else
  success "Step 1/9: macOS build tools (Xcode CLT) assumed present"
fi

# ── Step 2/9: Homebrew ────────────────────────────────────
info "Step 2/9: Installing Homebrew..."
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Ensure brew is on PATH for this session
if [[ "$(uname)" == "Darwin" ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    error "Homebrew installed but not found at /opt/homebrew or /usr/local"
  fi
else
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
success "Homebrew ready"

# ── Step 3/9: Install packages ────────────────────────────
info "Step 3/9: Installing packages via Brewfile..."
brew bundle --file="$DOTFILES_DIR/Brewfile"
success "All packages installed"

# ── Step 4/9: kitty on Linux ──────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
  info "Step 4/9: Installing kitty (Linux)..."
  if ! command -v kitty &>/dev/null; then
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
    mkdir -p ~/.local/bin
    ln -sfn ~/.local/kitty.app/bin/kitty ~/.local/bin/kitty
    ln -sfn ~/.local/kitty.app/bin/kitten ~/.local/bin/kitten
    success "kitty installed"
  else
    success "kitty already installed, skipping"
  fi
else
  success "Step 4/9: kitty installed via Homebrew (macOS)"
fi

# ── Step 5/9: Symlink configs ─────────────────────────────
info "Step 5/9: Linking configs to ~/.config/..."
mkdir -p "$HOME/.config"
for pkg in "${CONFIG_PACKAGES[@]}"; do
  ln -sfn "$DOTFILES_DIR/$pkg" "$HOME/.config/$pkg"
  echo "  $pkg -> ~/.config/$pkg"
done
success "All configs linked"

# ── Step 6/9: zsh setup ──────────────────────────────────
info "Step 6/9: Setting up zsh..."

# Backup existing non-symlink files
for f in "$HOME/.zshrc" "$HOME/.zimrc"; do
  if [[ -e "$f" && ! -L "$f" ]]; then
    warn "Backing up $(basename "$f") to $(basename "$f").bak"
    mv "$f" "$f.bak"
  fi
done

ln -sfn "$HOME/.config/zsh/zshrc" "$HOME/.zshrc"
ln -sfn "$HOME/.config/zsh/zimrc" "$HOME/.zimrc"
echo "  ~/.zshrc -> ~/.config/zsh/zshrc"
echo "  ~/.zimrc -> ~/.config/zsh/zimrc"

# Pre-download zimfw
ZIM_HOME="$HOME/.config/zsh/zim"
if [[ ! -e "$ZIM_HOME/zimfw.zsh" ]]; then
  echo "  Downloading zimfw..."
  mkdir -p "$ZIM_HOME"
  curl -fsSL -o "$ZIM_HOME/zimfw.zsh" \
    https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi
success "zsh configured"

# ── Step 7/9: vscode / cursor ────────────────────────────
info "Step 7/9: Linking vscode / cursor configs..."
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
    echo "  $(basename "$(dirname "$dir")") not found, skipping"
    continue
  fi
  for f in "${VSCODE_FILES[@]}"; do
    if [[ -e "$dir/$f" && ! -L "$dir/$f" ]]; then
      warn "Backing up $dir/$f to $dir/$f.bak"
      mv "$dir/$f" "$dir/$f.bak"
    fi
    ln -sfn "$HOME/.config/vscode/$f" "$dir/$f"
  done
  echo "  $(basename "$(dirname "$dir")")/User -> vscode/"
done
success "vscode / cursor configured"

# ── Step 8/9: Default shell ──────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
  info "Step 8/9: Setting default shell to zsh..."
  ZSH_PATH="$(which zsh)"
  if [[ "$SHELL" != "$ZSH_PATH" ]]; then
    if ! grep -qF "$ZSH_PATH" /etc/shells; then
      echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi
    chsh -s "$ZSH_PATH"
    success "Default shell set to zsh"
  else
    success "Default shell is already zsh"
  fi
else
  success "Step 8/9: macOS default shell is already zsh"
fi

# ── Step 9/9: Nerd Fonts ─────────────────────────────────
info "Step 9/9: Installing Nerd Fonts..."
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
    echo "  $name already installed"
    return
  fi
  echo "  Downloading $name..."
  local tmpdir
  tmpdir=$(mktemp -d)
  curl -fsSL -o "$tmpdir/$zip_name" \
    "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$zip_name"
  unzip -qo "$tmpdir/$zip_name" -d "$FONT_DIR" '*.ttf' '*.otf' 2>/dev/null || true
  rm -rf "$tmpdir"
}

install_nerd_font "FiraMono" "FiraMono.zip"
install_nerd_font "NerdFontsSymbolsOnly" "NerdFontsSymbolsOnly.zip"

# Refresh font cache on Linux
if [[ "$(uname)" != "Darwin" ]]; then
  fc-cache -f "$FONT_DIR" 2>/dev/null || true
fi
success "Nerd Fonts installed"

echo ""
success "All done! Restart your terminal to apply changes."
