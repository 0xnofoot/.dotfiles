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
├── .githooks/          # git hooks（pre-commit 检查扩展同步）
├── .docs/              # 维护文档（安装脚本更新 SOP 等）
└── vscode/             # vscode/cursor 配置（链接到 ~/.config/vscode，再按需链接到应用目录）
    ├── settings.json
    ├── keybindings.json
    ├── extensions.txt          # Code 和 Cursor 共享扩展
    ├── extensions-code.txt     # Code 独有扩展
    ├── extensions-cursor.txt   # Cursor 独有扩展
    ├── defaults/               # 各编辑器导出的默认快捷键 JSON（git 跟踪）
    └── scripts/
        ├── sync-extensions.sh             # 扩展列表同步脚本
        └── generate-disabled-defaults.py  # 默认快捷键禁用列表生成脚本
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
| Linux 编译工具 | Step 1/10 — apt/dnf/pacman 安装 build-essential 等 |
| Homebrew | Step 2/10 — 安装并配置 PATH |
| Brew bundle | Step 3/10 — 通过 Brewfile 安装所有包 |
| kitty 可选安装 | Step 4/10 — 默认跳过，`--with-kitty` 启用；macOS 用 cask，Linux 用官方脚本 |
| Symlink 循环 | Step 5/10 — 遍历 CONFIG_PACKAGES 链接到 `~/.config/`，同时配置 `core.hooksPath` |
| zsh 根级 symlink | Step 6/10 — `~/.zshrc`、`~/.zimrc` |
| vscode/cursor 配置 | Step 7/10 — 检测已安装的 Code/Cursor，将 `~/.config/vscode/` 下的配置文件链接到应用用户目录 |
| vscode/cursor 扩展 | Step 8/10 — 检测 code/cursor CLI，从 extensions*.txt 安装扩展 |
| 默认 shell | Step 9/10 — Linux 上设置 zsh 为默认 shell |
| Nerd Fonts | Step 10/10 — 自动下载安装 FiraMono + Symbols Nerd Font |
| 步骤总数 | 硬编码为 "Step N/10"，增减步骤时需全部更新 |

## VSCode 扩展管理

- 共享扩展写在 `vscode/extensions.txt`，Code 独有写在 `extensions-code.txt`，Cursor 独有写在 `extensions-cursor.txt`
- `install.sh` Step 8 自动检测 CLI 并安装
- 新增/删除扩展后，运行 `bash vscode/scripts/sync-extensions.sh` 自动检测差异并同步
- pre-commit hook 会自动检查扩展列表是否同步，未同步时可选择自动修复并加入提交

## VSCode 快捷键管理

- `keybindings.json` 中 `//===== Auto Generated: Disabled Defaults =====//` 标记行将文件分为两个区域
- 标记行之上：手动维护的自定义绑定，按场景分类（`//==========` 一级分类，`//----------` 子分类）：
  - Cursor AI → 全局操作 → 编辑器操作 → 列表与弹窗导航 → 编辑器窗口与分组 → 底部面板与终端 → 书签 → 运行与调试 → 侧边栏导航（文件管理器/搜索/书签/SCM）
- 标记行之下：脚本自动生成的默认快捷键禁用条目，不要手动编辑
- 各编辑器导出的默认快捷键 JSON 存放在 `vscode/defaults/`（如 `vscode.json`、`cursor.json`），由 git 跟踪
- 编辑器大版本更新后，重新导出默认快捷键 JSON 覆盖对应文件，运行 `python3 vscode/scripts/generate-disabled-defaults.py` 刷新禁用列表
- 脚本自动读取 `vscode/defaults/*.json`，支持任意数量的 VSCode 系编辑器
- 脚本内置 `PRESERVE_COMMANDS` 排除列表，全选/复制/剪切/粘贴/撤销/重做等基础命令不会被禁用
- pre-commit hook 在 `vscode/defaults/` 有暂存变更时自动检查禁用列表一致性，不一致可选择自动生成并加入提交

## Git 规范

- 提交时使用中文 commit message

## 维护文档

- [安装脚本更新 SOP](.docs/install-update-sop.md) — 配置变更时如何更新安装脚本
