# 延迟评估 / 已弃用的 tmux 插件

记录明确搁置或试用后弃用的插件，以及重新评估的触发信号。决定装的时候直接在 `tmux.conf` 的 `@plugin` 列表追加，在 `.docs/USER.md` 的 tmux 章节补键位。

## 已弃用

### tmux-thumbs（2026-04 试装后放弃）

仓库：`fcsonline/tmux-thumbs`

**定位**：扫描当前 pane 可见文本，给每个"看起来像 ID"的字符串（SHA、URL、路径、端口等）叠 2 字母 hint，按 hint 一键复制/执行。

**弃用原因**：GitHub release **没有 `aarch64-apple-darwin` 预编译包**（只有 x86_64 Intel / Linux）。在 Apple Silicon 上首次启动会弹交互式对话框让选择 compile（需 Rust 工具链）或 download（无 arm64 包）。为了避免引入 Rust 工具链 + 编译延迟，放弃这个插件。

**何时重装**：
- 决定装 Rust 工具链到 Brewfile（`brew "rust"`，~200MB）
- 或上游补上 aarch64 release
- 或频繁需要从屏幕提取 SHA / URL / 路径的场景，手动 copy-mode 效率不够

## 延迟评估

### 1. tmux-notify

仓库：`rickstaa/tmux-notify`

**定位**：监听当前 pane 的下一条命令，跑完弹 macOS / Linux 系统通知（或 status bar 闪烁）。

**触发场景**：长跑命令 + 切走干别的活的工作流 ——`cargo build --release`、大测试套件、`brew upgrade`、`docker build`。启动后 `prefix+N`（插件绑定）开始监听，好了提醒。

**何时装**：
- 一天至少 3 次"启动长命令 → 切走 → 忘记回来看"的循环
- 愿意 `brew install terminal-notifier` 拿到更漂亮的 macOS 通知

**为何搁置**：当前没有明确的长命令监控需求；tmux 自带 `bell-action` + `monitor-activity` 能粗粒度替代（不过视觉提示较弱）。

### 2. extrakto

仓库：`laktak/extrakto`

**定位**：**整个 pane scrollback 一次性喂给 fzf**，你输关键词搜命中字符串（URL、路径、数字等），选中 `Enter` 复制或 `Tab` insert 到命令行。

**触发键**：`prefix+Tab`（默认）。

**何时装**：
- 已弃用的 thumbs 场景里经常遇到"想要的字符串已经滚出屏幕"
- 喜欢 `Tab` insert 到命令行（不执行）的工作流
- 经常从 log 里捞特定关键字

**为何搁置**：目前靠 tmux-jump + copy-mode + 系统剪贴板已经够用；extrakto 增量价值需实际用到才清楚。

**依赖**：Python 3 + fzf（fzf 已有）。

### 3. tmux-sessionx

仓库：`omerxx/tmux-sessionx`

**定位**：内置 `choose-tree` 的加强版。

**比 choose-tree 多的**：
- `Ctrl-W` 从 zoxide 目录列表新建 session（最高频增量）
- `Ctrl-X` 杀 session 带确认 + 预览
- `Ctrl-F` 全局 pane 内容搜索（choose-tree 的 `/` 只搜名字）
- `Tab` 预览选中 session 的完整 pane 截图
- 新建 session 时可选 layout 模板

**触发键**：`prefix+O`（默认）。

**何时装**：
- 已装 zoxide（Brewfile 里已有 ✅）
- 发现自己频繁 `tmux new-session -s <name> -c <path>` 这个流程
- 项目数 > 5 且经常需要"从任意目录新建 session"

**为何搁置**：当前 `prefix+s` 的 choose-tree + `/` 搜索已够用；sessionx 的增量价值取决于是否真的频繁创建临时 session。

### 4. tmux-open

仓库：`tmux-plugins/tmux-open`

**定位**：copy-mode 里选中一段文本，按键直接用系统默认程序打开。

**默认键位**（都在 copy-mode-vi）：
- `o` — 用系统 `open`/`xdg-open`（URL → 浏览器、路径 → 对应应用）
- `Ctrl-o` — 用 `$EDITOR` 打开（路径 → nvim）
- `S` — 用搜索引擎搜（默认 Google）

**何时装**：
- copy-mode 用得很多（log 分析、长输出浏览）
- 想要"选中就能开"的低成本流程

**为何搁置**：M-v copy-mode + tmux-jump 的组合已经覆盖选区 + 光标瞬移；tmux-open 的增量价值需实际用到才知道。

## 重新评估的信号清单

| 现象 | 装哪个 |
|------|--------|
| 多次"启动长命令，切走忘回来看"的循环 | tmux-notify |
| 频繁想提取 scrollback 里已滚出屏幕的字符串 | extrakto |
| 频繁从一个陌生目录起 tmux session | tmux-sessionx |
| copy-mode 里框选 URL / 路径想一键打开 | tmux-open |
| pane marking 用得少 | 保留，零成本；内置功能 |

卸载某个插件：从 `tmux.conf` 的 `set -g @plugin '…'` 删掉那一行，`prefix+alt-u`（TPM 内置快捷键）清理，或手动 `rm -rf ~/.config/tmux/plugins/<name>`。
