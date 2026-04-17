# macOS 权限配置指南

> **平台限定**:本方案(macism / im-select / SketchyVim / AeroSpace / SwipeAeroSpace / Karabiner-Elements)**仅支持 macOS**,Linux 上不安装也不加载对应配置。
>
> 相关守卫:
> - `Brewfile` 整段 `if OS.mac? ... end`
> - `svim/.config.sh`、`aerospace/.config.sh`、`karabiner/.config.sh` 顶部 `[[ "$(uname)" != "Darwin" ]] && exit 0`
> - `nvim/lua/config/plugins/editor.lua` 的 AutoIMSwitch 包一层 `if vim.fn.has("mac") == 1`
> - `zsh/vim.zsh` 的 `zvm_after_select_vi_mode` 顶部 `[[ "$OSTYPE" != darwin* ]] && return`

本文档列出 macOS Vim Everywhere 方案中需要在「系统设置」里手动授权的项目。
所有权限均位于 **系统设置 → 隐私与安全性**。

---

## 1. 辅助功能（Accessibility）

路径:系统设置 → 隐私与安全性 → 辅助功能

需加入并开启开关的应用:

| 应用 | 用途 | 备注 |
|------|------|------|
| SketchyVim (`svim`) | 在系统文本框注入 Vim 键位 | 不会自动出现在列表中,需按 `+` 手动添加 `/opt/homebrew/bin/svim`(在添加面板按 `Cmd+Shift+G` 粘贴路径) |
| AeroSpace | 平铺窗口管理 | 首次启动会弹窗请求 |
| SwipeAeroSpace | 三指滑动切换 workspace | 首次启动会弹窗请求 |
| Karabiner-Elements | 低层按键重映射 | 首次启动会弹窗请求 |

---

## 2. 输入监控(Input Monitoring)

路径:系统设置 → 隐私与安全性 → 输入监控

需开启开关:

| 应用 | 用途 |
|------|------|
| `karabiner_grabber` | Karabiner 抓取底层按键事件(仅启用 Karabiner 方案时需要) |
| `karabiner_observer` | Karabiner 观察按键(同上) |

> Karabiner 首次安装会自动提示这两项,跟随向导即可。

---

## 3. 屏蔽冲突的系统快捷键

### 3.1 Spotlight `Cmd+Space`

路径:系统设置 → 键盘 → 键盘快捷键 → Spotlight

- 取消勾选 **显示 Spotlight 搜索**
- 原因:该快捷键通常会被 Raycast / Alfred 等启动器占用,系统级 Spotlight 会抢占

### 3.2 输入法切换 `Ctrl+Space`(如启用 Karabiner 右 Cmd 切换)

路径:系统设置 → 键盘 → 键盘快捷键 → 输入法

- 可保留系统默认(不冲突),或按个人习惯调整

### 3.3 Mission Control / 桌面切换

路径:系统设置 → 键盘 → 键盘快捷键 → Mission Control

- 若使用 AeroSpace 的 workspace 功能,建议关闭 `Ctrl+← / Ctrl+→` 的"切换桌面"快捷键,避免与窗口操作冲突

---

## 4. 登录项(可选)

路径:系统设置 → 通用 → 登录项

| 应用 | 建议 |
|------|------|
| AeroSpace | 按需关闭(也可在 `aerospace.toml` 中设 `start-at-login = false`) |
| Karabiner-Elements | 保持开启(依赖其后台服务) |
| SketchyVim | 由 `brew services` 管理,无需在此配置 |

---

## 5. 快速自检命令

```bash
# 二进制是否就位
which macism im-select svim

# SketchyVim 是否在运行
brew services list | grep svim

# 当前输入法 ID(切到中文后再跑一次,确认 ID 与 karabiner.json 匹配)
macism
```

---

## 6. 验证顺序

1. 先装依赖:`bash ~/.dotfiles/install.sh`
2. 首次启动各 App,按弹窗授权
3. 手动补齐:SketchyVim 的辅助功能(需手动添加),Spotlight 禁用
4. 重启 Karabiner-Elements 让规则生效:`launchctl kickstart -k gui/$(id -u)/org.pqrs.service.agent.karabiner_console_user_server` 或直接重启系统
