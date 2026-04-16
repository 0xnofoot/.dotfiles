# 全局行为规则

## 网络搜索与页面抓取

内置的 WebSearch 和 WebFetch 工具已被禁用，所有网络访问改用 Tavily MCP：

| 需求 | 使用工具 |
|------|----------|
| 网络搜索 | `mcp__tavily__tavily_search` |
| 抓取指定 URL 内容 | `mcp__tavily__tavily_extract` |
| 深度多源研究 | `mcp__tavily__tavily_research` |
| 爬取网站结构 | `mcp__tavily__tavily_crawl` |
| 映射网站 URL 结构 | `mcp__tavily__tavily_map` |
| 查询库/API 文档 | `mcp__tavily__tavily_skill` |


## Speckit 新需求工作流

执行 `/speckit.specify` 开启新需求时，按以下顺序初始化（顺序不可颠倒）：

1. 询问用户本次需求使用的编号 `NNN`（由用户自行确认，避免自动探测遗漏其他进行中的 worktree）
2. 从需求描述推导 `<shortname>`（kebab-case，2-4 词），组合为 `<name> = NNN-<shortname>`
3. 检测项目主分支名称（`main` 或 `master`，取实际存在的那个）
4. 确保 `.worktrees/` 目录已被 `.gitignore` 忽略：若 `.gitignore` 中不存在该条目，追加 `.worktrees/`；若 `.worktrees/` 目录不存在，自动创建
5. 执行 `git worktree add .worktrees/<name> -b <name> <主分支>`，基于主分支创建独立 worktree
6. 运行 `create-new-feature.sh`，**必须传入 `--number NNN`** 强制使用同一编号，防止脚本扫描分支列表时产生编号漂移。**脚本调用方式**：用子 shell + 绝对路径，避免 GVM 等 shell 钩子劫持 `cd` 导致路径解析失败：
   ```bash
   WORKTREE_ABS="$(pwd)/.worktrees/<name>"
   (cd "$WORKTREE_ABS" && /bin/bash .specify/scripts/bash/create-new-feature.sh "<描述>" --number NNN --short-name "<shortname>")
   ```
   > **禁止**用 `cd dir && bash script.sh` 的单行写法——GVM 的 `cd` 钩子会在 bash 子进程启动时以相对路径重新执行 `cd`，导致 `no such file or directory` 报错。
7. 后续所有文件操作均在该 worktree 目录内进行
8. 告知用户：worktree 路径和分支名，说明后续所有 `/speckit.*` 命令均在此目录内继续执行。**不要提示清理命令**——worktree 在整个功能开发周期内都应保持存在，仅在功能分支合并到主分支后，用户才需要执行 `git worktree remove .worktrees/<name>` 清理。

> **关键约束**：步骤 5（建 worktree）必须早于步骤 6（跑脚本），且步骤 6 必须传 `--number`；否则脚本会将步骤 5 新建的分支计入编号，导致编号 +1 漂移。

## Speckit 输出语言规则

执行任何 `/speckit.*` 命令生成文档内容时，遵循以下语言规则：

### 核心原则：结构英文，内容中文

所有 speckit 生成的文档中，**人类阅读的描述性内容**用简体中文撰写，**机器解析的结构性标记**保持英文原样。

### 保持英文的判断模式（符合任一条即保留英文）：

1. **Markdown 章节标题** — 以 `#` 开头的行，保持模板原有的英文标题
2. **加粗字段名** — 模板中 `**FieldName**:` 格式的标签（如 `**Language/Version**:`、`**Independent Test**:`），冒号前的字段名保持英文
3. **编号标识符** — 匹配 `字母-数字` 或 `字母+数字` 模式的 ID（如 FR-001、SC-001、T001、CHK001、US1）
4. **方括号标记** — 模板定义的方括号标记（如 [P]、[US1]、[NEEDS CLARIFICATION]、[Gap]）
5. **大写关键词** — 全大写的英文标记词（如 NEEDS CLARIFICATION、N/A、MVP、CRITICAL、HIGH、MEDIUM、LOW、MUST、SHOULD）
6. **BDD 关键词** — Given、When、Then
7. **复选框语法** — `- [ ]`、`- [X]`、`- [x]`
8. **技术标识** — 文件路径、代码引用、Git 分支名、框架名、语言名、工具名、命令名
9. **优先级标记** — P1、P2、P3 等
10. **脚本交互** — JSON 键名、脚本输出的结构化字段

### 用简体中文撰写（符合任一条即用中文）：

1. **描述性文本** — 解释"是什么"、"为什么"、"怎么做"的自然语言段落和句子
2. **字段值** — `**FieldName**:` 冒号后面的具体描述内容（技术术语本身除外）
3. **列表项内容** — 需求、假设、边界情况等列表中，标识符之后的描述文字
4. **场景描述** — Given/When/Then 关键词后面的具体场景内容
5. **决策与理由** — 技术决策、选择原因、被否决方案的说明
6. **注释和备注** — HTML 注释中的指导说明、文档末尾的备注
7. **分析结论** — 报告中的发现摘要、修复建议、覆盖率说明
