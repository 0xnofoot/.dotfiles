# 网络访问规则（按需加载）

> **触发条件**：需要网络访问时——搜索网络信息、查询外部/最新资料、抓取 URL 或网页内容。

内置 WebSearch 和 WebFetch 已禁用，所有网络访问改走自托管 SearXNG MCP。

| 需求 | 使用工具 |
|------|----------|
| 网络搜索 | `mcp__searxng__searxng_web_search` |
| 抓取 URL 内容（转 Markdown，支持分段 / 章节 / 段落切片） | `mcp__searxng__web_url_read` |

> 仅提供搜索与 URL 抓取两个工具；多源研究、站点爬取、站点映射等高级能力需自行组合调用。
