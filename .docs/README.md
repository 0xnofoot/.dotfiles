# .dotfiles

macOS / Linux 跨平台 dotfiles，统一 Gruvbox Dark 主题，Vi 键位贯穿全栈。Homebrew 统一包管理，每个应用目录下一份 `.config.sh` 负责链接与特有安装逻辑，`install.sh` 自动扫描调用。

## 包含工具

| 工具 | 说明 |
|------|------|
| [kitty](https://sw.kovidgoyal.net/kitty/) | GPU 加速终端模拟器（可选安装） |
| [tmux](https://github.com/tmux/tmux) | 终端复用器 |
| [Neovim](https://neovim.io/) | 编辑器，Lazy.nvim 管理插件 |
| [yazi](https://yazi-rs.github.io/) | 终端文件管理器 |
| [bottom](https://github.com/ClementTsang/bottom) | 终端系统监视器（`btm`） |
| [lazygit](https://github.com/jesseduffield/lazygit) | Git TUI，pager 接 delta |
| [zsh](https://www.zsh.org/) + [Zim](https://zimfw.sh/) | Shell + 插件框架（vi-mode / 高亮 / 补全 / fzf-tab） |
| [Starship](https://starship.rs/) | 跨平台 prompt |
| [atuin](https://atuin.sh/) | Shell 历史增强，接管 `Ctrl+R` |
| [fzf](https://github.com/junegunn/fzf) | 模糊搜索 |
| [delta](https://github.com/dandavison/delta) | Git diff 高亮 |
| [jless](https://jless.io/) | JSON 交互浏览器 |
| VS Code / Cursor | 编辑器配置（settings / keybindings / 扩展清单） |
| [Claude Code](https://claude.com/claude-code) | Anthropic CLI 配置 |
| [AeroSpace](https://github.com/nikitabobko/AeroSpace) | 平铺窗口管理器（macOS 限定） |
| [Karabiner-Elements](https://karabiner-elements.pqrs.org/) | 键位改造 + 输入法切换（macOS 限定） |

## 安装

```bash
git clone https://github.com/0xnofoot/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
bash install.sh
```

可选参数：`--with-kitty` 安装 kitty（默认跳过）。

安装脚本会顺序执行：

1. 安装编译工具（macOS 跳过，Linux 用 apt / dnf / pacman）
2. 安装 Homebrew
3. 通过 `Brewfile` 安装所有依赖包
4. 扫描各应用目录下的 `.config.sh`，逐一链接配置并完成应用特有操作（扩展增量安装、kitty 可选安装、zsh 根级 symlink、Linux 默认 shell 设置等）
5. 安装 Nerd Fonts（FiraMono + Symbols）

重启终端即可生效。

## 跨平台差异

| 项目 | macOS | Linux |
|------|-------|-------|
| 包管理 | Homebrew（原生） | Linuxbrew |
| kitty 安装 | `brew install --cask kitty` | 官方安装脚本 |
| kitty 快捷键 | `Cmd + 字母` | `Super + 字母` |
| VS Code / Cursor 配置路径 | `~/Library/Application Support/{Code,Cursor}/User/` | `~/.config/{Code,Cursor}/User/` |
| 默认 shell | 已是 zsh | 脚本自动 `chsh` |
| 字体目录 | `~/Library/Fonts/` | `~/.local/share/fonts/` |
| AeroSpace / Karabiner / 输入法切换 | 安装并链接 | 完全跳过 |

macOS 首次运行需在「系统设置 → 隐私与安全性」手动授权 AeroSpace / Karabiner，详见 [macos-permissions-setup.md](macos-permissions-setup.md)。

## 自定义

- `zsh/local.zsh` — 本机专属配置（已被忽略，不入库）
- `nvim/lua/config/machine_specific.lua` — Neovim 本机覆盖
- `Brewfile` — 增删依赖后运行 `brew bundle`

新增 / 删除应用、管理 VSCode 扩展等维护操作，参见 [install-update-sop.md](install-update-sop.md)。
