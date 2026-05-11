# 全局行为规则

> 本文件在每次会话启动时由 Claude Code 自动加载。常驻规则直接写在本文件；触发式规则通过文末索引表按需加载。

## 网络访问

内置 WebSearch 和 WebFetch 已禁用，所有网络访问改走自托管 SearXNG MCP。

| 需求 | 使用工具 |
|------|----------|
| 网络搜索 | `mcp__searxng__searxng_web_search` |
| 抓取 URL 内容（转 Markdown，支持分段 / 章节 / 段落切片） | `mcp__searxng__web_url_read` |

> 仅提供搜索与 URL 抓取两个工具；多源研究、站点爬取、站点映射等高级能力需自行组合调用。

## 其他非常驻规则

非常驻规则统一放在 `~/.claude/on-demand/`，**不在本文件展开**。命中下表任一触发条件时，在执行该场景的实际工作**之前**，先用 Read 工具加载对应文件；同一会话内已读过则无需重复读取。

| 触发条件 | 加载文件 |
|----------|---------|
| 用户执行任何 `/speckit.*` 命令（specify / plan / tasks / implement 等） | `~/.claude/on-demand/speckit.md` |
