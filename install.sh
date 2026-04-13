#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_PACKAGES=(kitty tmux nvim yazi zsh)

info()    { printf "\033[1;34m==>\033[0m \033[1m%s\033[0m\n" "$1"; }
success() { printf "\033[1;32m==>\033[0m \033[1m%s\033[0m\n" "$1"; }
warn()    { printf "\033[1;33m==>\033[0m \033[1m%s\033[0m\n" "$1"; }
error()   { printf "\033[1;31m==>\033[0m \033[1m%s\033[0m\n" "$1"; exit 1; }

# ── Step 1/7: Homebrew ────────────────────────────────────
info "Step 1/7: Installing Homebrew..."
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Ensure brew is on PATH for this session
if [[ "$(uname)" == "Darwin" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)"
else
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
success "Homebrew ready"

# ── Step 2/7: Install packages ────────────────────────────
info "Step 2/7: Installing packages via Brewfile..."
brew bundle --file="$DOTFILES_DIR/Brewfile"
success "All packages installed"

# ── Step 3/7: kitty on Linux ──────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
  info "Step 3/7: Installing kitty (Linux)..."
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
  success "Step 3/7: kitty installed via Homebrew (macOS)"
fi

# ── Step 4/7: Symlink configs ─────────────────────────────
info "Step 4/7: Linking configs to ~/.config/..."
mkdir -p "$HOME/.config"
for pkg in "${CONFIG_PACKAGES[@]}"; do
  ln -sfn "$DOTFILES_DIR/$pkg" "$HOME/.config/$pkg"
  echo "  $pkg -> ~/.config/$pkg"
done
success "All configs linked"

# ── Step 5/7: zsh setup ──────────────────────────────────
info "Step 5/7: Setting up zsh..."

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

# ── Step 6/7: vscode / cursor ────────────────────────────
info "Step 6/7: Linking vscode / cursor configs..."
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
    ln -sfn "$DOTFILES_DIR/vscode/$f" "$dir/$f"
  done
  echo "  $(basename "$(dirname "$dir")")/User -> vscode/"
done
success "vscode / cursor configured"

# ── Step 7/7: Default shell ──────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
  info "Step 7/7: Setting default shell to zsh..."
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
  success "Step 7/7: macOS default shell is already zsh"
fi

echo ""
success "All done! Restart your terminal to apply changes."
