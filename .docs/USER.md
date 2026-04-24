# Dotfiles 使用指南

安装完成后的系统配置、日常使用约定，以及 tmux 完整键位参考。安装步骤见 [README.md](README.md)。

---

## 1. macOS 首次运行：系统设置授权

> **平台限定**：以下内容（macism / im-select / Karabiner-Elements）**仅 macOS 需要**，Linux 上所有相关配置均已加守卫自动跳过，无需操作。

首次在 macOS 运行 `bash install.sh` 完成后，以下授权需手动在「系统设置 → 隐私与安全性」里补齐。

### 1.1 辅助功能（Accessibility）

| 应用 | 用途 |
|------|------|
| Karabiner-Elements | 低层按键重映射（首次启动会弹窗） |

### 1.2 输入监控（Input Monitoring）

| 应用 | 用途 |
|------|------|
| `karabiner_grabber` | Karabiner 抓取底层按键事件 |
| `karabiner_observer` | Karabiner 观察按键 |

Karabiner 首次安装会自动提示这两项，跟随向导即可。

### 1.3 屏蔽冲突的系统快捷键

- **Spotlight `Cmd+Space`**：系统设置 → 键盘 → 键盘快捷键 → Spotlight → 取消勾选 **显示 Spotlight 搜索**（让位给 Raycast / Alfred）

### 1.4 登录项

保持 Karabiner-Elements 开启（依赖后台服务）。

### 1.5 快速自检

```bash
# 二进制就位
which macism im-select

# 当前输入法 ID（切到中文后再跑一次，确认 ID 与 karabiner.json 匹配）
macism
```

### 1.6 验证顺序

1. `bash ~/.dotfiles/install.sh`
2. 首次启动各 App，按弹窗授权
3. 手动屏蔽 Spotlight
4. 重启 Karabiner 让规则生效：`launchctl kickstart -k gui/$(id -u)/org.pqrs.service.agent.karabiner_console_user_server`（或直接重启系统）

---

## 2. tmux 使用指南

当前 tmux 配置（插件 + 自定义键位）的完整使用方式。

- prefix = `C-s`
- `prefix+x` 表示先按 C-s 再按 x；`M-x` 表示 Alt/Option+x，**不需要 prefix**

### 2.1 键位速查表

| 键 | 行为 | 来源 |
|----|------|------|
| `M-h` / `M-j` / `M-k` / `M-l` | tmux pane 切换（左/下/上/右） | tmux 原生 |
| `M-f` | 打开 / 关闭 floax 持久化 scratchpad（全局） | tmux-floax |
| `M-_` / `M-+` / `M-)` | popup 内缩小 / 放大 / 重置尺寸（只在 popup 内生效） | tmux-floax |
| `prefix+j` | tmux-jump 单字符定位 | tmux-jump |
| `prefix+m` / `prefix+M` | 标记 / 取消标记当前 pane | 内置（自绑） |
| `prefix+S` | 当前 pane 与 marked pane 互换（跨 window/session） | 内置（自绑） |
| `prefix+J` | 把 marked pane 拉进当前 window | 内置（自绑） |
| `prefix+y` | choose-buffer：浏览 / 粘贴 / 删除多剪贴板栈 | 内置（自绑） |
| `prefix+Ctrl-s` | resurrect 手动保存全部 session | tmux-resurrect |
| `prefix+Ctrl-r` | resurrect 手动恢复最近快照 | tmux-resurrect |
| `prefix+s` | choose-tree：fuzzy 切 session（`/` 搜索） | tmux 原生 |
| `prefix+w` | choose-tree：fuzzy 切 window | tmux 原生 |
| `prefix+:` 进 command-prompt | `:new-session -s name -c path` 等动态命令 | tmux 原生 |

### 2.2 tmux-floax 持久化 scratchpad

`M-f` 打开一个浮动 popup，**第一次**会建一个名为 `scratch` 的独立 session。再按 `M-f` 关闭，**shell 继续在后台跑**。

**杀手级场景**：把 `lazygit` 或 REPL 挂在里面，随叫随到。

```
# 第一次：M-f
# popup 里跑 lazygit
$ lazygit

# M-f 关闭（lazygit 仍在跑，只是 popup 隐藏了）
# 过 5 秒后需要看 git 状态：M-f
# lazygit 还在那里，光标位置都没变
```

**popup 内部的缩放键**（`session_name == scratch` 时才生效，外部按会透传给 shell）：

| 键 | 行为 |
|----|------|
| `M-_` | 缩小 popup |
| `M-+` | 放大 popup |
| `M-)` | 重置为 `@floax-width/height`（默认 80%/80%） |

**配置**（`tmux.conf` 插件块里）：`@floax-change-path true` 让每次打开都跟随当前 pane 路径，`@floax-session-name scratch` 定了 session 名。

**插件原生 chord 已全部禁用**：floax 原本在 popup 打开时会把 `C-M-s/b/f/r/e/d/u` 注册到 server root（server 全局生效、易误触且 lock 链路不可靠）。`tmux/scripts/floax-toggle.sh` 在每次 toggle 后立即 unbind 这 7 个 chord，并用上面的 `M-f/M-_/M-+/M-)` 替代。Shift+Alt 组合依赖 tmux `extended-keys on`（在 tmux.conf 顶部已开），让 kitty 的 CSI u 序列被识别为 `M-<shifted>`。

### 2.3 tmux-jump

按输入的**单字符**做光标瞬移，像 vim 的 EasyMotion。

**用法**：
- `prefix+j` → 屏幕变暗，光标变输入提示
- 按一个字符（比如 `/`）→ 屏幕上所有 `/` 位置出现 2 字母 hint
- 按 hint → 光标跳到那个位置（进入 copy-mode，可以继续 yank/select）

**场景**：
- copy-mode 里选长行，想精准跳到第 3 个 `=` —— `prefix+j` → `=` → 选 hint
- 快速 yank 某个单词，不想用 `/` 搜索

**依赖**：Ruby（macOS 自带）

### 2.4 Resurrect + Continuum

`tmux-resurrect` 负责 **save/restore**，`tmux-continuum` 负责**定时自动 save**（不自动 restore，避免启动时强制恢复旧布局）。

**手动操作（推荐主要走这两个）**：
- `prefix+Ctrl-s` —— 保存所有 session/window/pane 布局、工作目录、pane 内容快照到 `~/.local/share/tmux/resurrect/`
- `prefix+Ctrl-r` —— 从最近的快照恢复

**自动**：
- `@continuum-save-interval 15` —— 每 15 分钟后台存一次，crash / 忘按 `prefix+Ctrl-s` 时的安全网
- **启动不自动恢复** —— 新起的 tmux 就是空的，要恢复请 `prefix+Ctrl-r`

**nvim 自动重启**：`@resurrect-strategy-nvim 'session'` —— pane 里开着 nvim 时，恢复时 nvim 通过 `:mksession` 机制回到 buffer 和光标位置。

**pane 内容快照**（`@resurrect-capture-pane-contents on`）会把每个 pane 当前可见文本存进快照，恢复后能看到之前的 scrollback（只是当时屏幕可见部分，不是完整历史）。

**典型流程**：

```
# 场景 A：布局改乱了回滚
prefix+Ctrl-s    # 布局好的时候先存
... 瞎改一通 ...
prefix+Ctrl-r    # 一键还原

# 场景 B：机器重启 / tmux crash
tmux             # 空起（因为关了 auto restore）
prefix+Ctrl-r    # 手动拉回上次快照（continuum 的 15min auto-save 兜底）
```

### 2.5 Copy-mode 里的 vim-style 复制快捷键

`M-v` 进 copy-mode 后，除了标准的 `v` 选择 / `y` 复制选区之外，以下**无选区**直接复制：

| 按键 | 行为 |
|------|------|
| `yy` | 复制当前行 |
| `yw` / `ye` | 复制到下一个 word 结尾（即当前 word） |
| `yb` | 复制到上一个 word 开头 |
| `y.` | 复制到行尾 |
| `y,` | 复制到行首（第 0 列） |
| `yi<符号>` | 复制包围符号内部，支持 `"` `'` `` ` `` `(` `)` `[` `]` `{` `}` |

**工作原理**：`y` 在没有选区时会切到 `copy-mode-vi-yank` 子表，等下一个按键决定复制范围（类似 vim operator+motion）。`yi` 再切到 `copy-mode-vi-yank-inside` 子表等待符号输入。复制后自动写进 tmux buffer 栈和系统剪贴板。

**yi 的实现近似**：`jump-backward 左界 → cursor-right → begin-selection → jump-forward 右界 → cursor-left → copy`。不如 vim 的 text object 智能（不处理嵌套、跨行），但覆盖单行常见场景足够。

### 2.6 Buffer stack（`prefix+y`）

tmux 内部维护一个独立于系统剪贴板的 buffer 栈，每次 copy-mode 里 `y` 都会 push 一条，最多 50 条。

**`prefix+y`**（choose-buffer）：
- 列出栈里所有 buffer，右侧预览选中条的内容
- `Enter` 粘到当前 pane（等价于 `prefix+]` 粘最新，但可选任意条）
- `d` 删除光标所在条
- `/` fuzzy 搜索 buffer 内容
- `Escape` 取消

**联动系统剪贴板**：`set -g set-clipboard on` 让 yank 同时写进系统剪贴板和 tmux 栈，两边并行。

### 2.7 Pane marking 工作流

tmux 允许标记**最多 1 个** pane 作为"第二指针"，结合 swap/join 命令可以跨 window、跨 session 重新编排布局。

**键位**：
- `prefix+m` —— 标记当前 pane（pane border 上会多一个 `*`）
- `prefix+M` —— 取消标记
- `prefix+S` —— 当前 pane 和 marked pane 互换位置（跨 window / session）
- `prefix+J` —— 把 marked pane 拉过来作为当前 window 的新 pane

**典型场景**：

```
# window=main 里 pane 3 开着 test 运行
# 想把它拉到 window=logs 集中看
prefix+m                # 在 pane 3 标记
切到 window logs
prefix+J                # marked pane 变成 logs window 的新 pane
```

**原子 pane 互换**：两个 pane 分屏位置不爽，一边太窄：

```
prefix+m            # 标记 pane A
切到 pane B（比如 M-l）
prefix+S            # AB 互换
```

### 2.8 tpm 插件管理（走 CLI，不绑快捷键）

tpm 默认的 `prefix+I` / `prefix+U` / `prefix+Alt-u` 都在 `tmux.conf` 末尾 unbind 掉了。想管理插件就跑对应脚本：

| 操作 | 命令 |
|------|------|
| 安装 `@plugin` 声明的新插件 | `~/.config/tmux/plugins/tpm/bin/install_plugins` |
| 升级所有插件 | `~/.config/tmux/plugins/tpm/bindings/update_plugins all` |
| 升级单个插件 | `~/.config/tmux/plugins/tpm/bindings/update_plugins <repo-name>` |
| 清理从 `@plugin` 删除的插件 | `~/.config/tmux/plugins/tpm/bindings/clean_plugins` |

改了 `tmux.conf` 的 `@plugin` 列表后：

```bash
# 新增：加 @plugin 行 → 装
~/.config/tmux/plugins/tpm/bin/install_plugins

# 删除：去掉 @plugin 行 → 清
~/.config/tmux/plugins/tpm/bindings/clean_plugins

# 重载配置
tmux source-file ~/.config/tmux/tmux.conf
```

**注意**：`install.sh` 的 `tmux/.config.sh` 也会自动跑 `install_plugins`，所以走 `bash ~/.dotfiles/install.sh` 也能幂等安装插件（更新需要手动跑 `update_plugins all`）。

### 2.9 进一步调优（可选，不在本次安装范围）

如果发现这些高频操作不够快，可以在 `tmux.conf` 手加：

```tmux
# 带默认值的重命名
bind R command-prompt -I "#W" "rename-window '%%'"
bind , command-prompt -I "#S" "rename-session '%%'"

# 快速新建 session
bind C command-prompt -p "new session:" "new-session -d -s '%%' \; switch-client -t '%%'"

# 切最近两个 session
bind -n M-Backspace switch-client -l
```

### 2.10 常见问题

- **Alt 键不生效**：kitty 里确认 `macos_option_as_alt yes`（macOS）；终端模拟器如果把 Alt 当 Meta 转义，tmux 的 M-h 可能变成 `\eh` 然后丢失 —— 正常 kitty + tmux 组合不会
- **Shift+Alt+符号（M-+ / M-_ / M-) 等）按了透传给 shell，没被 tmux 拦下**：这类组合在 kitty 下走 CSI u 序列，tmux 默认关闭 extended-keys 所以不识别。tmux.conf 顶部的 `set -s extended-keys on` + `set -as terminal-features 'xterm*:extkeys'` 解这个问题。新改动没生效时先 `tmux kill-server` 重启一次 server（extended-keys 是 server 级 flag）。想验证 chord 能否到达 tmux：`tmux bind -n M-+ display-message "fired"` 然后按键看状态栏
- **prefix+Ctrl-s 按不出来**：prefix 就是 C-s，所以"按住 Ctrl 不放，按两次 s"。物理上就是 Ctrl+s+s
- **TPM 首次装后插件没加载**：跑 `~/.config/tmux/plugins/tpm/bin/install_plugins`，然后 `tmux source-file ~/.config/tmux/tmux.conf` 或 `tmux kill-server` 再起
- **floax popup 打不开**：确认 tmux >= 3.2（`tmux -V`），低版本不支持 display-popup
- **M-f 在 popup 内按了没关闭**：floax 用 session 名判断是否在 popup 内，确认 popup 里 `tmux display -p '#{session_name}'` 输出是 `scratch`
- **tmux-jump 无反应**：依赖 Ruby，`ruby --version` 验证（macOS 自带；Linux 可能需 `apt install ruby`）
