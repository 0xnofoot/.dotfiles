# Dotfiles 项目说明

## 仓库结构

```
.dotfiles/
├── install.sh          # 一键安装脚本（macOS + Linux）
├── Brewfile            # Homebrew 依赖清单
├── kitty/              # kitty 终端配置
├── tmux/               # tmux 配置
├── nvim/               # neovim 配置
├── yazi/               # yazi 文件管理器配置
├── zsh/                # zsh 配置（特殊：需要根级 symlink）
└── vscode/             # vscode/cursor 配置（链接到 ~/.config/vscode，再按需链接到应用目录）
```

## 安装机制

- 包管理：macOS 和 Linux 统一使用 Homebrew
- 配置链接：每个 `<app>/` 目录通过 `ln -sfn` 链接到 `~/.config/<app>`
- 依赖声明：所有 brew/cask 包写在 `Brewfile` 中
- zsh 特殊处理：除 `~/.config/zsh` 外，还需 `~/.zshrc` 和 `~/.zimrc` 根级 symlink
- vscode 特殊处理：同样链接到 `~/.config/vscode`，再检测已安装的 Code/Cursor，将配置文件链接到对应应用用户目录（macOS/Linux 路径不同）

## install.sh 关键位置

| 内容 | 位置 |
|------|------|
| 配置包列表 | `CONFIG_PACKAGES=(kitty tmux nvim yazi zsh vscode)` — 第 5 行 |
| Linux 编译工具 | Step 1/9 — apt/dnf/pacman 安装 build-essential 等 |
| Homebrew | Step 2/9 — 安装并配置 PATH |
| Brew bundle | Step 3/9 — 通过 Brewfile 安装所有包 |
| Linux kitty 安装 | Step 4/9 — macOS 用 cask，Linux 用官方安装脚本 |
| Symlink 循环 | Step 5/9 — 遍历 CONFIG_PACKAGES 链接到 `~/.config/` |
| zsh 根级 symlink | Step 6/9 — `~/.zshrc`、`~/.zimrc` |
| vscode/cursor 配置 | Step 7/9 — 检测已安装的 Code/Cursor，将 `~/.config/vscode/` 下的配置文件链接到应用用户目录 |
| 默认 shell | Step 8/9 — Linux 上设置 zsh 为默认 shell |
| Nerd Fonts | Step 9/9 — 自动下载安装 FiraMono + Symbols Nerd Font |
| 步骤总数 | 硬编码为 "Step N/9"，增减步骤时需全部更新 |

## Git 规范

- 提交时使用中文 commit message

## 维护文档

- [安装脚本更新 SOP](.docs/install-update-sop.md) — 配置变更时如何更新安装脚本
