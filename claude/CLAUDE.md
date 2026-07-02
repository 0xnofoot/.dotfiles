# 全局行为规则

> 本文件在每次会话启动时由 Claude Code 自动加载。常驻规则直接写在本文件；触发式规则通过文末索引表按需加载。

- 优先使用codebase-memory-mcp进行结构性代码查询

## 非常驻规则

非常驻规则统一放在 `~/.claude/on-demand/`，**不在本文件展开**。命中下表任一触发条件时，在执行该场景的实际工作**之前**，先用 Read 工具加载对应文件；同一会话内已读过则无需重复读取。

| 触发条件 | 加载文件 |
|----------|---------|
| 需要网络访问：搜索网络信息、查最新外部资料、抓取 URL/网页内容时 | `~/.claude/on-demand/web-access.md` |
| 需要结构性代码查询：探索代码库、找定义/调用者/调用链/依赖/实现、影响分析、找死代码时（含在 Bash 里准备用 `rg`/`grep`/`find`/`fd` 搜代码的场景） | `~/.claude/on-demand/code-discovery.md` |
| 用户执行任何 `/speckit.*` 命令（specify / plan / tasks / implement 等） | `~/.claude/on-demand/speckit.md` |
