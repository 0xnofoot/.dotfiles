---
name: codegraph-index
description: 为当前项目及所有子仓建立/刷新 CodeGraph 索引。用户说"建索引"/"索引子仓"/"为多仓建索引"/"codegraph 索引"等时触发。自行寻找含 .git 的子仓库，跳过已索引且 up to date 的仓库，对新仓库或 stale 仓库执行 codegraph init/sync。也支持查询当前已索引仓库（codegraph explore/query）。
---

# codegraph

CodeGraph 是本地代码知识图（SQLite + tree-sitter AST），索引后 AI agent 可一次调用拿到符号源码 + 调用路径（含动态分派）+ blast radius，替代 grep/Read 循环。本 skill 负责**多仓索引**——为当前项目根 + 所有子仓建立/刷新索引。

## Prerequisites

```bash
# codegraph CLI（已装则跳过）
command -v codegraph || npm i -g @colbymchenry/codegraph
# PATH（若 which codegraph 空，npm 全局在 /opt/homebrew/bin）
export PATH="/opt/homebrew/bin:$PATH"
codegraph --version  # 验证
```

## 索引（agent path）

**驱动脚本**：`~/.claude/skills/codegraph-index/scripts/index-all.sh`

扫根目录 + 所有子仓（含 `.git` 的目录，限深 3 层，排除 node_modules/Pods/build 等纯依赖），逐仓库判定后 init/sync：

```bash
bash ~/.claude/skills/codegraph-index/scripts/index-all.sh "$PWD"
# 大仓库后台并行：
bash ~/.claude/skills/codegraph-index/scripts/index-all.sh "$PWD" --parallel
```

脚本逻辑（已验证）：
- 找 `.git` 仓库 → 已有 `.codegraph/` 且 `codegraph status` 含 "up to date" → 跳过。
- 有 `.codegraph/` 但 stale → `codegraph sync`（增量）。
- 无 `.codegraph/` → `codegraph init`（首次建图 + 启文件监听自动增量）。
- `--parallel`：android/ios/flutter 等大仓后台并行，小仓前台串行。
- 结束输出汇总表（仓库 | 文件数 | 节点数）。

## 查询（索引就绪后）

```bash
codegraph explore "<符号名或问题>"   # 核心：源码+调用路径+blast radius
codegraph callers <符号>            # 谁调用
codegraph callees <符号>            # 它调用了谁
codegraph impact <符号>             # 改动影响面
codegraph query <搜索词>            # 搜符号(FTS5)
codegraph status                    # 索引状态
```

MCP 工具（Claude Code 会话内，重启后可用）：`codegraph_explore`（同 CLI explore，行号源码可直接 Edit）。

> MCP 按当前工作目录选对应仓库的 `.codegraph/`。跨子仓查询需 `cd` 到目标仓库或分别查。

## 状态/同步

```bash
codegraph status              # 当前仓库索引状态 + 统计
codegraph sync                # 手动增量同步（默认文件监听自动增量）
codegraph index --force       # 全量重建（损坏/强制）
codegraph daemon              # 管理后台监听进程
```

## Gotchas

- **根仓库索引只覆盖根自身代码**：子仓是独立 `.git`，根 init 跳过嵌套仓库。必须用 index-all.sh 或 cd 进子仓单独 init。
- **大仓库首次 init 耗时**：ios（86万节点量级）/ flutter（10万+）/ android（14万+）可能数十分钟，用 `--parallel` 后台并行。
- **空间占用**：索引 ≈ 源码 × 30%（ios 2.7G 源码 → ~800M 索引）。磁盘不足提示。
- **纯依赖必排除**：脚本已 grep 排除 node_modules/Pods/build/.pub-cache/dist/vendor/.gradle/.dart_tool/DerivedData。勿索引 Pods（CocoaPods）否则爆炸。
- **锁文件**：`codegraph status` 报 lock 阻塞 → `codegraph unlock` 清理后重试。
- **多仓各自独立图**：每个子仓独立 `.codegraph/`，无原生跨仓合并图。跨仓调用链（如 Flutter Pigeon→原生）需分别查或手动关联。

## Troubleshooting

| 症状 | 修复 |
|---|---|
| `codegraph: command not found` | `npm i -g @colbymchenry/codegraph` + `export PATH="/opt/homebrew/bin:$PATH"` |
| `index-all.sh` 找不到子仓 | 确认子仓目录有 `.git`（ftc 管理的子仓库应含） |
| init 卡住/报 lock | `codegraph unlock <path>` 清锁重试 |
| status 报 stale 但 sync 无变化 | 文件监听进程挂了，`codegraph daemon` 重启或 `codegraph index --force` 全量重建 |
| 大仓 init OOM | codegraph 1.4.1+ 已修流式索引（PR #900），升级 `codegraph upgrade` |
| MCP `codegraph_explore` 不可用 | 重启 Claude Code 让 MCP 配置加载 |
