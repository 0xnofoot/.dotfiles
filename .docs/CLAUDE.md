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
│   ├── .config.sh      # 逐文件链接受管条目到 ~/.claude，保留运行时数据；据 settings.json 同步 plugin
│   ├── CLAUDE.md       # 全局规则 + 非常驻规则索引（按需 Read 加载）
│   ├── settings.json
│   ├── commands/       # 自定义 slash commands
│   ├── skills/         # 自定义 skills（如 codebase-memory 知识图谱）
│   ├── hooks/          # 自定义 hooks（PreToolUse/SessionStart，由 settings.json 引用）
│   └── on-demand/      # 非常驻规则目录，命中触发条件时按需加载
│       └── speckit.md  # /speckit.* 命令专属规则
├── claude-mem/         # claude-mem 插件配置
│   ├── .config.sh      # 只软链 settings.json 到 ~/.claude-mem，保留运行时数据（db/chroma/logs 等）
│   └── settings.json   # claude-mem 配置（模型/端口/上下文注入/provider 等）
├── .docs/              # 维护文档（README.md / CLAUDE.md / USER.md 真实文件、install SOP、tmux 延迟评估记录等）
├── karabiner/          # Karabiner-Elements 键位改造（Vim Everywhere 组件）
│   ├── .config.sh      # 链接整目录到 ~/.config/karabiner
│   ├── .gitignore      # 排除 automatic_backups/（运行时备份）
│   └── karabiner.json
├── vscode/             # vscode/cursor 配置
│   ├── .config.sh      # 链接配置文件到应用用户目录 + 检测 CLI 安装扩展
│   ├── settings.json
│   ├── keybindings.json
│   ├── extensions/             # 扩展列表
│   │   ├── shared.txt          # Code 和 Cursor 共享扩展
│   │   ├── code.txt            # Code 独有扩展
│   │   ├── cursor.txt          # Cursor 独有扩展
│   │   └── vsix.txt            # 需要 VSIX 本地安装的扩展
│   ├── default-keybindings/    # 各编辑器导出的默认快捷键 JSON（git 跟踪）
│   └── scripts/
│       ├── sync-extensions.sh             # 扩展列表同步脚本
│       └── generate-disabled-defaults.py  # 默认快捷键禁用列表生成脚本
└── jetbrains/          # JetBrains 系 IDE（AS / IDEA / PyCharm ...）配置
    ├── .config.sh      # 扫描已安装产品链接 keymap + 根级链 ~/.ideavimrc;插件靠 IDE 内 Marketplace 手装
    ├── keymaps/
    │   └── Custom.xml  # parent="VSCode OSX" 的差异 keymap(焦点/分屏/调试/书签等)
    ├── ideavimrc       # IdeaVim 配置;sethandler 路由 ctrl/Tab/Space 到 IDE 或 vim,详见下方"特殊处理"
    └── plugins.txt     # 必装插件清单(VSCode Keymap / IdeaVim)
```

## 安装机制

- 包管理：macOS 和 Linux 统一使用 Homebrew
- 配置链接与应用特有操作：每个 `<app>/` 目录下维护一份 `.config.sh`，由 `install.sh` Step 4 自动扫描并逐一调用；脚本负责配置链接，也可包含应用特有的安装/设置逻辑（如扩展安装、默认 shell 设置等）；所有脚本通过父进程导出的 `DOTFILES_DIR` 定位源文件，目标存在时直接删除后重建软链接，失败则通过 `error()` 终止安装
- 依赖声明：所有 brew/cask 包写在 `Brewfile` 中
- tmux / nvim / yazi / bottom：整目录链接到 `~/.config/<app>`
- tmux 特殊处理：TPM 走 XDG 路径，插件装到 `~/.config/tmux/plugins/`，物理上落在仓库 `tmux/plugins/`（由 `tmux/.gitignore` 排除）。`.config.sh` 显式 `export TMUX_PLUGIN_MANAGER_PATH` 并调用 `install_plugins` headless 自动装完所有 `@plugin` 声明的插件（否则 TPM 会 fallback 到 `~/.tmux/plugins/`）
- kitty 特殊处理：`--with-kitty` 时先安装 kitty（macOS 用 cask，Linux 用官方脚本），再链接配置目录
- zsh 特殊处理：整目录链接到 `~/.config/zsh`，同时在 `~/` 创建 `.zshrc`、`.zimrc` 根级 symlink（直接指向 `$DOTFILES_DIR/zsh/`），预下载 zimfw 到 `zsh/zim/`，Linux 上设置 zsh 为默认 shell；Linux 按需生成 `en_US.UTF-8` locale（优先 locale-gen，fallback localedef），配合 `zsh/env.zsh` 强制的 LANG/LC_ALL=en_US.UTF-8 避免 zle 退回 8-bit 模式
- vscode 特殊处理：不经 `~/.config/vscode` 中间层，直接检测已安装的 Code/Cursor，将 `settings.json`、`keybindings.json` 链接到对应应用用户目录（macOS/Linux 路径不同），随后检测 CLI 增量安装扩展；未安装时输出提示并跳过
- claude 特殊处理：不链接整目录，逐文件将受管条目（`CLAUDE.md`、`settings.json`、`commands/`、`skills/`、`hooks/`、`on-demand/`）链接到 `~/.claude`，运行时数据（历史记录、缓存等）保留在 `~/.claude` 真实目录中，不进入仓库。**`hooks/` 含 codebase-memory-mcp 安装的 `cbm-code-discovery-gate`（PreToolUse Grep/Glob/Find）与 `cbm-session-reminder`（SessionStart），均由 settings.json 引用；这两个文件工具升级时会改写，整目录软链后改写会写穿污染仓库，git diff 时按"工具是编辑器、dotfiles 是版本控制"心态接受**。**codebase-memory-mcp 安装**：`.config.sh` 的 `install_codebase_memory_mcp` 调官方 `install.sh --skip-config` 把 269MB 编译二进制按 OS/arch 下载到 `~/.local/bin/codebase-memory-mcp`（**不入库**，含 checksum 校验与 macOS 重签名）；**必须 `--skip-config`**——官方默认的"配置 agent"步骤会重写 `cbm-*` hooks 并注册 MCP，而 cbm hooks 已由仓库 `claude/hooks/` + `settings.json` 管理（软链），让官方写会写穿污染仓库。MCP 改用 `claude mcp add --scope user codebase-memory-mcp <bin>` 显式注册到 `~/.claude.json` 顶层（与 `mcpServers` 一致，`~/.claude.json` 是不入库的本机状态）；二进制**不存在才下载**，升级需手动删除 `~/.local/bin/codebase-memory-mcp` 后重跑（或直接跑官方 `install.sh`）。缺 `claude`/网络失败均跳过、不中断安装。**plugin 跨机同步**：`settings.json` 的 `extraKnownMarketplaces`（插件源）+ `enabledPlugins`（启用清单）是 plugin 配置的单一真相源，`.config.sh` 末尾 `sync_claude_plugins` 在装机时用 `claude plugin marketplace add` / `claude plugin install --scope user` 据此重建（`value=false` 的装后 `disable`）；`installed_plugins.json` 与 `plugins/cache/` 是本机运行时状态（含绝对 installPath、版本、commit SHA），**不入库**、由 CLI 自动生成。同步依赖 `jq`（Brewfile 已含）解析、依赖 `claude` CLI（公司内部包 `@futupb/ft-claude-code`，install.sh 不安装它）——二者缺一则跳过同步、不中断安装；仅重建 settings.json 里**声明了的**插件，手动装但无声明的（如 disabled 的 cortex，源信息不在 settings）不会被同步。**symlink 会被反复冲断**：Claude Code 写任何设置（`/plugin install`、enable/disable、切模型）走"写临时文件 + rename"原子替换，会把 `~/.claude/settings.json` 从 symlink 打回普通文件，运行时状态滞留 live 不回流仓库；需手动 `cp ~/.claude/settings.json claude/settings.json && ln -sfn "$PWD/claude/settings.json" ~/.claude/settings.json`（顺序不能反，否则丢运行时状态）或重跑 `.config.sh` 重建。这是 settings.json 混了"配置"与"运行时状态"的固有矛盾，同 hooks 写穿一样按"工具是编辑器、dotfiles 是版本控制"心态接受
- claude-mem 特殊处理：不链接整目录，只把 `settings.json` 软链到 `~/.claude-mem`，其余全是运行时数据（`claude-mem.db` / `chroma/` / `logs/` / `observer-sessions/` / `*.pid` 等）保留在 `~/.claude-mem` 真实目录中，不入库。settings.json 是**纯配置**（模型/端口/上下文注入/provider 等），入库时几个 `*_API_KEY`（Gemini/OpenRouter/Chroma/Telegram/Server）与 `*_BOT_TOKEN` 字段均为空——**若日后填了 key，因是 symlink 会直接写进仓库文件被 git 跟踪，提交前务必清空或改用其他注入方式，避免泄密**。文件里 `CLAUDE_MEM_DATA_DIR` / `CLAUDE_MEM_TRANSCRIPTS_CONFIG_PATH` 是**绝对路径**（含用户名），跨到不同用户名/OS 的机器需手动修正或让 claude-mem 重新生成。**symlink 同样会被冲断**：claude-mem 从 UI/CLI 改设置走原子写会把 symlink 打回普通文件，需重跑 `.config.sh` 或手动 `cp ~/.claude-mem/settings.json claude-mem/settings.json && ln -sfn "$PWD/claude-mem/settings.json" ~/.claude-mem/settings.json`（顺序不能反），同 claude settings.json 按"工具是编辑器、dotfiles 是版本控制"心态接受
- lazygit 特殊处理：`zsh/env.zsh` 导出 `XDG_CONFIG_HOME=~/.config`，使 macOS 上的 lazygit 也读取 `~/.config/lazygit`，与 Linux 路径统一
- git 特殊处理：不走 symlink。用户 `~/.gitconfig` 只保留私有内容（`[user]`、`[commit] template`、`[url] insteadOf`、`[core] hooksPath` 等）不入库，仓库用 `git/common.gitconfig` 集中维护公共片段（含 delta、excludesfile 等所有通用配置），由 `.config.sh` 幂等地 `git config --global --add include.path` 接入
- jetbrains 特殊处理：JetBrains 系 IDE 配置目录版本化（`AndroidStudio<ver>/`、`IntelliJIdea<ver>/` ...），`.config.sh` 用前缀白名单 glob 匹配 `~/Library/Application Support/{Google,JetBrains}/<Product><ver>/`（Linux 对应 `~/.config/{Google,JetBrains}/`），只把 `keymaps/Custom.xml` 链接进去；**不管 `options/keymap.xml`**——IDE 会回写该文件,symlink 会被穿透污染仓库,改成首次启动后到 Settings > Keymap 手动切到 Custom。`Custom.xml` 用 `parent="VSCode OSX"`,只写 diff,依赖用户先在 Marketplace 装 VSCode Keymap 插件;JetBrains 没有稳定的插件 CLI,`plugins.txt` 仅作清单提示。**Settings Sync / Settings Repository 启用时云端会回写覆盖 keymaps/,需在 IDE 内禁用同步或把 keymap 排除在同步范围外**。**IDE 改动 keymap 后会重写 `Custom.xml`(action 按字母排序、注释丢失、空 action 节点保留)**,这是 by design,git diff 时按"IDE 是编辑器,dotfiles 是版本控制"心态接受。IdeaVim 配置 `ideavimrc` 同目录维护(共用此分类),`.config.sh` 在 IDE 检测之前先做 `~/.ideavimrc` 根级 symlink(IdeaVim 不走 XDG),即使没装 IDE 也链接,避免后装 IDE 时漏配。**`ideavimrc` 里 sethandler 路由策略**:`ctrl+h/l/b/f/m` 全模式给 IDE(避开 vim 默认语义);`ctrl+j/k` 全模式给 vim,insert 模式 `imap <C-j> <Down>` / `imap <C-k> <Up>` 翻译成方向键——补全弹窗(lookup)用 swing 内部 InputMap 只认硬编码方向键,普通 keymap action 进不去,翻译成方向键才能选 next/prev item;`Tab`/`S-Tab` 在 insert 给 IDE(配合 keymap 把 `EditorLookupSelectionDown/Up` 绑到 tab/shift+tab 实现补全切换),normal/visual 留给 vim(`<C-i>` == `<Tab>` 的 jumplist Forward 不受影响);`Space` 全模式给 vim,否则 IDE keymap 里 `space w`/`space l` 之类的 chord 会拦下空格输入

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
| Brew bundle | Step 3/5 — 通过 Brewfile 安装所有包；`--upgrade` 强制升级已有包，保证多机滚动到同一最新版（Homebrew 不支持精确 pin 到 patch 版本，统一滚动是唯一跨机对齐策略） |
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
5. **带副作用的 `eval "$(tool init zsh)"` 一律放顶层，不要塞进 `zvm_after_init` 等函数体内** — 第三方 init 脚本（如 fzf 0.71+）在顶层会包含无条件 `return`（0.70 及之前只有条件 return），放在函数体里 eval 时 `return` 会让宿主函数提前退出，后续 eval（atuin、starship 等）全部静默跳过。顶层 eval 时 `return` 只退出 eval 自身，不影响后续语句。配合各自的幂等守卫（自定义 flag 或自带 env 变量）避免重复 source `~/.zshrc` 时重载
6. **不要依赖第三方工具的内部函数名做守卫** — starship 1.25+ 把函数名前缀从 `starship_` 改成 `prompt_starship_`，旧守卫 `${+functions[starship_precmd]}` 直接永远为假导致反复 init。守卫用自己定义的**不导出**的 shell-local flag（`_STARSHIP_INITED=1`、`_FZF_INITED=1`、`_ATUIN_INITED=1`），不要用工具自己 `export` 的 env 变量（如 atuin 的 `$ATUIN_SESSION`）——export 的变量会被子 shell 继承，yazi `S`、`tmux new-window` 等起的新 zsh 会误判已 init 直接跳过，子 shell 里 widget 未注册、Ctrl+R 回退到默认 `bck-i-search`
7. **atuin 18.x 的 widget 按 keymap 分名** — 没有叫 `_atuin_search` 的 widget（那只是内部函数），bindkey 要按 keymap 用 `atuin-search`（emacs）/`atuin-search-viins`（viins）/`atuin-search-vicmd`（vicmd）。另外 zsh-vi-mode 初始化时会重建 viins/vicmd keymap，顶层 atuin init 的 Ctrl+R 绑定会被清掉，必须在 `zvm_after_init` 里按 keymap 重绑一次

## 优化 version manager（RVM / nvm / pyenv / rbenv / asdf）启动时

改这类 version manager 的启动耗时时，**必须分两层加载**，只要有一层错就会在非 shell 场景下炸：

1. **PATH 段 eager** — shell 启动时就把 manager 托管的 `rubies/<ver>/bin`、`gems/<ver>/bin` 等 prepend 到 `/usr/bin` 之前。`#!/usr/bin/env ruby` 这种 shebang 链、嵌套的 `env ruby_executable_hooks`（CocoaPods pod_execute.sh）、GUI / launchd / CI 子进程全部绕开 shell function 只认 PATH；只 stub 函数不动 PATH 等于把这些场景拱手让给 `/usr/bin/ruby 2.6`（macOS 自带，EOL）
2. **manager 函数 lazy** — `source ~/.rvm/scripts/rvm` 这种 ~200ms 重初始化，可以用 stub（`unset self + source 真 rvm + 以原参重放`）延迟到用户真的敲 `rvm` 时再触发

**具体做法**：从 manager 的 "默认版本" symlink 读版本名，prepend 对应 bin 到 PATH 最前：

| manager | 默认版本来源 | 要 prepend 的 bin |
|---------|------------|-----------------|
| RVM | `~/.rvm/environments/default`（由 `rvm --default use <ver>` 维护）| `gems/<ver>/bin`、`gems/<ver>@global/bin`、`rubies/<ver>/bin` |
| nvm | `~/.nvm/alias/default` | `~/.nvm/versions/node/<ver>/bin` |
| pyenv | `~/.pyenv/version` 文件内容 | `~/.pyenv/versions/<ver>/bin` |
| rbenv | `~/.rbenv/version` 文件内容 | `~/.rbenv/versions/<ver>/bin` |
| asdf | `~/.tool-versions` 每行 | 各 plugin 的 `installs/<name>/<ver>/bin` |

踩坑记录：2026-04-27 把 RVM 改成 stub + lazy 时只 append 了 `~/.rvm/bin`（只含 `rvm` 命令本体），丢掉了 `rubies/3.3.0/bin`，6 分钟后用户 `pod install` 命中 /usr/bin/ruby 2.6 崩（base64 gem 缺）。修复见 commit `aba3822`。

## Git 规范

- 提交时使用中文 commit message

## 维护文档

- [安装脚本更新 SOP](install-update-sop.md) — 配置变更时如何更新安装脚本
- [tmux 延迟评估插件](tmux-deferred-plugins.md) — 已弃用 / 延迟评估的 tmux 插件记录与重新评估信号
- [USER.md](USER.md) — 用户侧使用指南（tmux 键位、macOS 授权等），用户文档改动应同步此处
