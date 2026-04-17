# .dotfiles

macOS / Linux 跨平台 dotfiles，统一 Gruvbox Dark 主题，Vi 键位贯穿全栈。

## 包含工具

| 工具 | 说明 |
|------|------|
| [kitty](https://sw.kovidgoyal.net/kitty/) | GPU 加速终端模拟器 |
| [tmux](https://github.com/tmux/tmux) | 终端复用器 |
| [Neovim](https://neovim.io/) | 编辑器，Lazy.nvim 管理插件 |
| [yazi](https://yazi-rs.github.io/) | 终端文件管理器 |
| [zsh](https://www.zsh.org/) + [Zim](https://zimfw.sh/) | Shell + 插件框架 |
| [Starship](https://starship.rs/) | 跨平台 prompt |
| [fzf](https://github.com/junegunn/fzf) | 模糊搜索 |
| VS Code / Cursor | 编辑器配置（可选） |

## 安装

```bash
git clone https://github.com/0xnofoot/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
bash install.sh
```

重启终端即可生效。安装脚本会自动完成以下 10 步：

1. 安装 Linux 编译工具（macOS 跳过）
2. 安装 Homebrew
3. 通过 Brewfile 安装所有依赖
4. 安装 kitty 终端（默认跳过，`--with-kitty` 启用）
5. Symlink 配置目录到 `~/.config/`（含 vscode）
6. 设置 zsh 根级 symlink（`~/.zshrc`、`~/.zimrc`）+ 下载 Zim
7. 检测已安装的 VS Code / Cursor，将 `~/.config/vscode/` 下的配置文件链接到对应应用目录
8. 安装 VS Code / Cursor 扩展（从 extensions/ 目录读取）
9. 设置 zsh 为默认 shell（Linux）
10. 安装 Nerd Fonts（FiraMono + Symbols）

## 仓库结构

```
.dotfiles/
├── install.sh          # 一键安装脚本
├── Brewfile            # Homebrew 依赖清单
├── kitty/              # kitty 终端配置
├── tmux/               # tmux 配置
├── nvim/               # Neovim 配置（Lazy.nvim）
├── yazi/               # yazi 文件管理器配置
├── zsh/                # zsh 配置
│   ├── zshrc           # 主入口
│   ├── zimrc           # Zim 插件声明
│   ├── env.zsh         # 环境变量
│   ├── vim.zsh         # Vi-mode 配置
│   ├── alias.zsh       # 别名
│   ├── plugs.zsh       # 插件初始化
│   ├── local.zsh       # 本机覆盖（不入库）
│   ├── starship/       # Starship prompt 配置
│   └── fzf/            # fzf 集成
├── .githooks/          # git hooks（pre-commit 检查扩展同步）
└── vscode/             # VS Code / Cursor 配置
    ├── settings.json
    ├── keybindings.json
    ├── extensions/             # 扩展列表（共享 / Code 独有 / Cursor 独有 / VSIX）
    ├── default-keybindings/    # 各编辑器导出的默认快捷键 JSON
    └── scripts/                # 同步扩展、生成禁用列表脚本
```

## 快捷键速查

### Kitty

macOS 使用 `Cmd`，Linux 使用 `Super`（Win 键）。

| 快捷键 | 功能 |
|--------|------|
| `Cmd/Super + C` | 复制 |
| `Cmd/Super + V` | 粘贴 |
| `Cmd/Super + +/-/0` | 字体大小 |
| `Cmd/Super + W` | 关闭窗口 |
| `Cmd/Super + Q` | 退出 |
| `Cmd/Super + N` | 新建窗口 |

> 已执行 `clear_all_shortcuts`，以上为全部快捷键，避免与 tmux/yazi 冲突。

### Tmux

Prefix 为 `Ctrl+S`。

| 快捷键 | 功能 |
|--------|------|
| `Prefix + n` | 新建窗口 |
| `Prefix + q` | 关闭窗口（需确认） |
| `Prefix + h/l` | 上/下一个窗口 |
| `Alt + 1-9` | 跳转到指定窗口 |
| `Alt + H/J/K/L` | 窗格导航 |
| `Alt + Q` | 关闭窗格 |
| `Alt + N/M` | 垂直/水平分割 |
| `Alt + ;` | 窗格缩放 |
| `Alt + F` | 弹出浮动终端 |
| `Alt + V` | 进入复制模式 |

### 浮动终端（Tmux Popup）

| 快捷键 | 功能 |
|--------|------|
| `Alt + Shift + Q` | 直接关闭 |
| `Alt + Q` | 确认后关闭 |

## Zsh 配置

### 插件（Zim 管理）

- **zsh-vi-mode** — Vi 模式
- **fast-syntax-highlighting** — 语法高亮
- **zsh-autosuggestions** — 自动建议
- **zsh-history-substring-search** — 历史子串搜索
- **zsh-autopair** — 括号自动配对
- **fzf-tab** — Tab 补全集成 fzf

### 常用别名

| 别名 | 实际命令 |
|------|---------|
| `ls` | `eza --icons` |
| `la` | `eza --icons -a` |
| `ll` | `eza --icons -la` |
| `v` | `nvim` |
| `t` | `tmux` |
| `f` | `fzf` |
| `j` | `yazi` |
| `cd` | `zoxide`（智能跳转） |
| `rm` | `trash-put`（安全删除） |

### Vi-Mode 增强

- 插入/普通/可视/替换模式各有独立光标样式
- `H/L/W/E/B` 加速移动（3x 步长）
- `,`/`.` 跳到行首/行尾，`'` 匹配括号

## 跨平台差异

| 项目 | macOS | Linux |
|------|-------|-------|
| 包管理 | Homebrew（原生） | Linuxbrew |
| kitty 安装 | `brew install --cask kitty`（可选） | 官方安装脚本（可选） |
| kitty 快捷键 | `Cmd + 字母` | `Super + 字母` |
| VS Code / Cursor 配置路径 | `~/Library/Application Support/{Code,Cursor}/User/` | `~/.config/{Code,Cursor}/User/` |
| 默认 shell | 已是 zsh | 脚本自动 `chsh` |
| 字体目录 | `~/Library/Fonts/` | `~/.local/share/fonts/` |

## 自定义

- **zsh/local.zsh** — 本机专属配置（已被 .gitignore 忽略），在此添加不想入库的环境变量或别名
- **nvim/lua/config/machine_specific.lua** — Neovim 本机覆盖
- **Brewfile** — 增删依赖后运行 `brew bundle`
