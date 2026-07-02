# 全局行为规则

> 本文件在每次会话启动时由 Claude Code 自动加载。常驻规则直接写在本文件；触发式规则通过文末索引表按需加载。

## Shell 命令（Bash 工具内）

在 **Bash 工具**里搜索时，**禁止调用裸 `grep` / `find`**，改用 `rg`（搜文本）、`fd`（找文件）；确需真 grep/find 语义时用 `command grep` / `/usr/bin/grep`（`find` 同理 `/usr/bin/find`）。

原因：Claude Code 的 shell-snapshot 把 `grep` 重定义为转发内嵌 ugrep（硬塞 `-G --ignore-files --hidden --exclude-dir=.git` 等）、`find` 转发内嵌 bfs，ugrep 不认 `-E`/`-A`/`--exclude-dir` 等选项，裸调用必报 `ugrep: bad option`。此行为绑定内部 ant-native 构建、**无用户可配开关**，snapshot 每会话重生成，改配置不持久——只能改用命令规避。shadow 只劫持 `grep`/`find` 这两个名字，本机装的真身用它们自己的名字 `ugrep`/`ug`（TUI）/`bfs` 直接调用不受影响（Brewfile 已含），需要 ugrep 特有能力（PCRE2、压缩包/PDF 内搜、`ug --query` 交互）时才用，否则 `rg`/`fd` 足够。

**结构性代码查询（找定义、调用链、影响分析、死代码）优先走 `codebase-memory` MCP**（详见 `~/.claude/on-demand/code-discovery.md`，触发时先加载）。**本主 agent 没有独立的 Grep/Glob/Find 工具**——文件级文本/文件名检索直接在 Bash 里用 `rg`/`fd`。内置 Grep/Glob 工具只存在于带这些工具的子 agent（如 Explore）里，它们触发 `cbm-code-discovery-gate` 补充图谱上下文，所以 `settings.json` 里 `Grep|Glob|Find` 的 PreToolUse matcher 仍有意义，勿删。

## 非常驻规则

非常驻规则统一放在 `~/.claude/on-demand/`，**不在本文件展开**。命中下表任一触发条件时，在执行该场景的实际工作**之前**，先用 Read 工具加载对应文件；同一会话内已读过则无需重复读取。

| 触发条件 | 加载文件 |
|----------|---------|
| 需要网络访问：搜索网络信息、查最新外部资料、抓取 URL/网页内容时 | `~/.claude/on-demand/web-access.md` |
| 需要结构性代码查询：探索代码库、找定义/调用者/调用链/依赖/实现、影响分析、找死代码时（含在 Bash 里准备用 `rg`/`grep`/`find`/`fd` 搜代码的场景） | `~/.claude/on-demand/code-discovery.md` |
| 用户执行任何 `/speckit.*` 命令（specify / plan / tasks / implement 等） | `~/.claude/on-demand/speckit.md` |
