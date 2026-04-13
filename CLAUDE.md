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
└── vscode/             # vscode/cursor 配置（特殊：文件级 symlink 到应用目录）
```

## 安装机制

- 包管理：macOS 和 Linux 统一使用 Homebrew
- 配置链接：每个 `<app>/` 目录通过 `ln -sfn` 链接到 `~/.config/<app>`
- 依赖声明：所有 brew/cask 包写在 `Brewfile` 中
- zsh 特殊处理：除 `~/.config/zsh` 外，还需 `~/.zshrc` 和 `~/.zimrc` 根级 symlink
- vscode 特殊处理：文件级 symlink 到 Code 和 Cursor 的用户配置目录（macOS/Linux 路径不同）

## install.sh 关键位置

| 内容 | 位置 |
|------|------|
| 配置包列表 | `CONFIG_PACKAGES=(kitty tmux nvim yazi zsh)` — 第 5 行 |
| Symlink 循环 | Step 4/7 — 遍历 CONFIG_PACKAGES 链接到 `~/.config/` |
| zsh 根级 symlink | Step 5/7 — `~/.zshrc`、`~/.zimrc` |
| vscode/cursor 配置 | Step 6/7 — 文件级 symlink 到应用用户目录 |
| Linux kitty 安装 | Step 3/7 — macOS 用 cask，Linux 用官方安装脚本（kitty 跨平台使用，非 macOS 专属） |
| 步骤总数 | 硬编码为 "Step N/7"，增减步骤时需全部更新 |

## 维护文档

- [安装脚本更新 SOP](.docs/install-update-sop.md) — 配置变更时如何更新安装脚本
