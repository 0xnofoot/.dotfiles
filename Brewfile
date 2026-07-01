# ============================================================
# 公共依赖（macOS + Linux 均安装）
# ============================================================

# Shell
brew "zsh"
brew "starship"
brew "atuin"

# Core Apps
brew "neovim"
brew "tmux"
brew "yazi"
brew "poppler"
brew "imagemagick"
brew "resvg"
brew "p7zip"

# CLI Tools
brew "tree-sitter-cli"
brew "fzf"
brew "fd"
brew "ripgrep"
brew "ugrep"                     # 独立真身；用 ugrep/ug 直接调用（Claude Code 的 grep shadow 不影响此名）
brew "bfs"                       # 广度优先 find，find 兼容语法
brew "bat"
brew "jless"
brew "jq"                        # claude/.config.sh 解析 settings.json 同步 plugin
brew "eza"
brew "lazygit"
brew "git-delta"
brew "zoxide"
brew "exiftool"
brew "mediainfo"
brew "trash-cli"
brew "tldr"
brew "bottom"
brew "node"                     # 提供 node/npx，用于 claude 插件运行时（claude-hud statusLine 等）

# Media
brew "mpv"

# ============================================================
# macOS 专属
# ============================================================
if OS.mac?
  # Vim Everywhere（输入法切换 / 键位改造）
  brew "laishulu/homebrew/macism"
  brew "daipeihust/tap/im-select"
  cask "karabiner-elements"
end

# ============================================================
# Linux 专属
# ============================================================
if OS.linux?
  # 系统工具
  brew "xclip"                  # 剪贴板桥接（Wayland/X11）
  brew "unzip"                  # install.sh 解压 Nerd Fonts
end
