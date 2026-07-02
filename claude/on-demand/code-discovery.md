# 代码库探索规则（按需加载）

> **触发条件**：需要进行结构性代码查询时——探索代码库结构、查找定义/调用者/调用链/依赖/实现、影响分析、找死代码。**尤其包括在 Bash 里准备用 `rg`/`grep`/`find`/`fd` 搜索代码的场景**：动手搜之前先加载本规则，判断该走 codebase-memory MCP 还是退回 `rg`/`fd`。

探索代码库、查找依赖、追踪调用链、影响分析、找死代码等结构性查询，**优先用 `codebase-memory` 知识图谱**（MCP 工具前缀 `mcp__codebase-memory-mcp__`），不可用或项目未索引时才退回 Bash 里的 `rg`/`fd`。**Bash 工具内禁止裸 `grep`/`find`**：Claude Code 的 shell-snapshot 把它们 shadow 成内嵌 ugrep/bfs，不认 `-E`/`-A`/`--exclude-dir` 等选项，裸调用必报 `ugrep: bad option`；改用 `rg`（搜文本）/`fd`（找文件），确需真 grep/find 语义用 `command grep`/`/usr/bin/find`。shadow 只劫持 `grep`/`find` 两个名字，真身 `ugrep`/`ug`（TUI）/`bfs` 用自身名字调用不受影响。带 Grep/Glob 工具的子 agent 也可用内置工具。具体工具映射与工作流见 `~/.claude/skills/codebase-memory/SKILL.md`。

项目可能嵌套（monorepo 子项目各自独立索引为独立 project）。调用前先 `list_projects`；存在嵌套时按**目标代码路径匹配最深的 `root_path`** 选 `project`，不要默认用最外层父项目。单个 project 查不到 ≠ 工具不可用——先换正确子项目重试，确认无误再退回 `rg`/`fd`。
