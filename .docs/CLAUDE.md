# Dotfiles 项目说明

## 仓库结构

```
.dotfiles/
├── install.sh          # 一键安装脚本（macOS + Linux）
├── Brewfile            # Homebrew 依赖清单
├── README.md           # → .docs/README.md 的 symlink，保留根目录入口
├── CLAUDE.md           # → .docs/CLAUDE.md 的 symlink，保留根目录入口
├── AGENTS.md           # → .docs/CLAUDE.md 的 symlink，给非 Claude 系 Agent 读取
├── kitty/              # kitty 终端配置
│   └── .config.sh      # 可选安装 kitty + 链接整目录到 ~/.config/kitty
├── tmux/               # tmux 配置
│   └── .config.sh      # 链接整目录到 ~/.config/tmux
├── nvim/               # neovim 配置
│   └── .config.sh      # 链接整目录到 ~/.config/nvim
├── yazi/               # yazi 文件管理器配置
│   └── .config.sh      # 链接整目录到 ~/.config/yazi
├── bottom/             # bottom (btm) 系统监视器配置
│   └── .config.sh      # 链接整目录到 ~/.config/bottom
├── lazygit/            # lazygit 配置（接入 delta 作为 pager）
│   └── .config.sh      # 链接整目录到 ~/.config/lazygit（依赖 XDG_CONFIG_HOME）
├── git/                # git 公共配置
│   ├── .config.sh      # 通过 git config --add include.path 接入 ~/.gitconfig
│   ├── common.gitconfig   # 公共 git 设置（core、pull、delta、merge 等）
│   └── gitignore_global   # 全局忽略（被 common.gitconfig 的 excludesfile 引用）
├── zsh/                # zsh 配置
│   └── .config.sh      # 链接整目录到 ~/.config/zsh，创建根级 symlink，Linux 设置默认 shell
├── .githooks/          # git hooks（pre-commit 检查扩展同步）
├── claude/             # Claude Code 配置
│   ├── .config.sh      # 逐文件链接受管条目到 ~/.claude，保留运行时数据
│   ├── CLAUDE.md
│   ├── settings.json
│   └── commands/       # 自定义 skills
├── .docs/              # 维护文档（README.md / CLAUDE.md 真实文件、SOP、权限指南等）
├── karabiner/          # Karabiner-Elements 键位改造（Vim Everywhere 组件）
│   ├── .config.sh      # 链接整目录到 ~/.config/karabiner
│   ├── .gitignore      # 排除 automatic_backups/（运行时备份）
│   └── karabiner.json
└── vscode/             # vscode/cursor 配置
    ├── .config.sh      # 链接配置文件到应用用户目录 + 检测 CLI 安装扩展
    ├── settings.json
    ├── keybindings.json
    ├── extensions/             # 扩展列表
    │   ├── shared.txt          # Code 和 Cursor 共享扩展
    │   ├── code.txt            # Code 独有扩展
    │   ├── cursor.txt          # Cursor 独有扩展
    │   └── vsix.txt            # 需要 VSIX 本地安装的扩展
    ├── default-keybindings/    # 各编辑器导出的默认快捷键 JSON（git 跟踪）
    └── scripts/
        ├── sync-extensions.sh             # 扩展列表同步脚本
        └── generate-disabled-defaults.py  # 默认快捷键禁用列表生成脚本
```

## 安装机制

- 包管理：macOS 和 Linux 统一使用 Homebrew
- 配置链接与应用特有操作：每个 `<app>/` 目录下维护一份 `.config.sh`，由 `install.sh` Step 4 自动扫描并逐一调用；脚本负责配置链接，也可包含应用特有的安装/设置逻辑（如扩展安装、默认 shell 设置等）；所有脚本通过父进程导出的 `DOTFILES_DIR` 定位源文件，目标存在时直接删除后重建软链接，失败则通过 `error()` 终止安装
- 依赖声明：所有 brew/cask 包写在 `Brewfile` 中
- tmux / nvim / yazi / bottom：整目录链接到 `~/.config/<app>`
- kitty 特殊处理：`--with-kitty` 时先安装 kitty（macOS 用 cask，Linux 用官方脚本），再链接配置目录
- zsh 特殊处理：整目录链接到 `~/.config/zsh`，同时在 `~/` 创建 `.zshrc`、`.zimrc` 根级 symlink（直接指向 `$DOTFILES_DIR/zsh/`），预下载 zimfw 到 `zsh/zim/`，Linux 上设置 zsh 为默认 shell
- vscode 特殊处理：不经 `~/.config/vscode` 中间层，直接检测已安装的 Code/Cursor，将 `settings.json`、`keybindings.json` 链接到对应应用用户目录（macOS/Linux 路径不同），随后检测 CLI 增量安装扩展；未安装时输出提示并跳过
- claude 特殊处理：不链接整目录，逐文件将受管条目（`CLAUDE.md`、`settings.json`、`commands/`）链接到 `~/.claude`，运行时数据（历史记录、缓存等）保留在 `~/.claude` 真实目录中，不进入仓库
- lazygit 特殊处理：`zsh/env.zsh` 导出 `XDG_CONFIG_HOME=~/.config`，使 macOS 上的 lazygit 也读取 `~/.config/lazygit`，与 Linux 路径统一
- git 特殊处理：不走 symlink。用户 `~/.gitconfig` 只保留私有内容（`[user]`、`[commit] template`、`[url] insteadOf`、`[core] hooksPath` 等）不入库，仓库用 `git/common.gitconfig` 集中维护公共片段（含 delta、excludesfile 等所有通用配置），由 `.config.sh` 幂等地 `git config --global --add include.path` 接入

## .config.sh 规范

每个应用的 `.config.sh` 须遵循以下约定：

- 首行 `#!/bin/bash`，次行 `set -e`，确保内部命令失败时立即退出
- `set -e` 之后用 `: "${DOTFILES_DIR:?must be set by install.sh}"` 强校验，脱离 install.sh 独立运行时立即失败，避免污染 `~/.gitconfig` 或生成坏 symlink
- 通过父进程导出的 `DOTFILES_DIR` 定位源文件，不使用相对路径
- 目标已存在时直接 `rm -rf` 删除，不备份
- 新增应用时，只需在其目录下创建 `.config.sh`，install.sh 自动发现并调用，无需修改 install.sh

## install.sh 关键位置

| 内容 | 位置 |
|------|------|
| Linux 编译工具 | Step 1/5 — apt/dnf/pacman 安装 build-essential 等 |
| Homebrew | Step 2/5 — 安装并配置 PATH |
| Brew bundle | Step 3/5 — 通过 Brewfile 安装所有包 |
| 链接配置 | Step 4/5 — 扫描所有子目录，逐一调用 `.config.sh`（失败则终止）；完成后配置 `core.hooksPath`；各应用的特有操作（扩展安装、kitty 可选安装、默认 shell 等）均由对应 `.config.sh` 处理 |
| Nerd Fonts | Step 5/5 — 自动下载安装 FiraMono + Symbols Nerd Font |
| 步骤总数 | 硬编码为 "Step N/5"，增减步骤时需全部更新 |

## VSCode 扩展管理

- 共享扩展写在 `vscode/extensions/shared.txt`，Code 独有写在 `extensions/code.txt`，Cursor 独有写在 `extensions/cursor.txt`
- 需要通过 VSIX 本地安装的扩展写在 `extensions/vsix.txt`（不在 Open VSX / VS Code Marketplace 上的扩展）
- `vscode/.config.sh` 自动检测 CLI 并增量安装（已安装的跳过），最后提示用户手动安装 VSIX 扩展
- 新增/删除扩展后，运行 `bash vscode/scripts/sync-extensions.sh` 自动检测差异并同步
- pre-commit hook 会自动检查扩展列表是否同步，未同步时可选择自动修复并加入提交；无 code/cursor CLI 时跳过检查

## VSCode 快捷键管理

- `keybindings.json` 中 `//===== Auto Generated: Disabled Defaults =====//` 标记行将文件分为两个区域
- 标记行之上：手动维护的自定义绑定，按场景分类（`//==========` 一级分类，`//----------` 子分类）：
  - Cursor AI → 全局操作 → 编辑器操作 → 列表与弹窗导航 → 编辑器窗口与分组 → 底部面板与终端 → 书签 → 运行与调试 → 侧边栏导航（文件管理器/搜索/书签/SCM）
- 标记行之下：脚本自动生成的默认快捷键禁用条目，不要手动编辑
- 各编辑器导出的默认快捷键 JSON 存放在 `vscode/default-keybindings/`（如 `vscode.json`、`cursor.json`），由 git 跟踪
- 编辑器大版本更新后，重新导出默认快捷键 JSON 覆盖对应文件，运行 `python3 vscode/scripts/generate-disabled-defaults.py` 刷新禁用列表
- 脚本自动读取 `vscode/default-keybindings/*.json`，支持任意数量的 VSCode 系编辑器
- 脚本内置 `PRESERVE_COMMANDS` 排除列表，全选/复制/剪切/粘贴/撤销/重做/查找等基础命令不会被禁用（查找类覆盖 cmd+f 在各 context 下绑定的所有 find/filter/search 命令）
- pre-commit hook 在 `vscode/default-keybindings/` 有暂存变更时自动检查禁用列表一致性，不一致可选择自动生成并加入提交

## 调试输入法 / zle widget 相关改动时

涉及输入法切换（`macism` / `im-select` / macOS TIS API）或 zsh zle widget（`zle-keymap-select` 等）的改动时，遵循以下顺序：

1. **先 reboot 再诊断** — macOS TIS 状态和 zsh 当前会话状态都会在调试过程中被污染（反复注册 widget wrapper、混用 macism/im-select、函数拷贝产生递归链等），在脏状态上演绎原理会得到完全错误的结论。改动前如果现象"看起来不对"，第一步必须重启验证基准行为
2. **不要混用 `macism` 和 `im-select`** — 两者调用 TIS 的路径不同，混用会让系统 IM 状态进入不一致（状态栏和真实输入法漂移）。`im-select` 切 CJK 有已知 bug（`macism` README 里明确列为反面案例），只用于避免 macism workaround 的窗口闪烁
3. **`macism` 切 CJK 时的窗口闪烁是设计** — macism 的默认行为会创建临时窗口抢焦点再还回去（`TemporaryWindow.app`），这是绕过 macOS IM 激活 bug 的 workaround，不是缺陷。`macism ID 0` 可以关闭 workaround 但会退化到 im-select 同样的漂移问题
4. **zle widget 链式包装要一次成型** — `functions -c src dst` 重复执行会把 dst 覆盖成 wrapper 本身，造成递归链（FUNCNEST 溢出或多次触发）。在同一 zsh 会话里迭代调试 widget 时，每次修改前先 `unfunction` 旧版本，或直接开新 kitty 窗口

## Git 规范

- 提交时使用中文 commit message

## 维护文档

- [安装脚本更新 SOP](install-update-sop.md) — 配置变更时如何更新安装脚本
