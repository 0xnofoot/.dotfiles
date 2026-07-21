# 代码发现规则

> **触发条件**:需要进行结构性代码查询时——探索代码库结构、查找定义/调用者/调用链/依赖/实现、影响分析、找死代码。**尤其包括在 Bash 里准备用 `rg`/`grep`/`find`/`fd` 搜索代码的场景**:动手搜之前先加载本规则,判断该走 CodeGraph 还是退回 `rg`/`fd`。

## 优先级

1. **项目已索引(根目录有 `.codegraph/`)→ 用 CodeGraph,别 grep**:
   - MCP 工具(会话内可用时):`codegraph_explore` 一次返回相关符号源码 + 调用路径(含 grep 跟不到的动态分派跳转)+ blast radius。查询里点名符号或文件名,精确度更高。
   - Shell(MCP 不可用时):`codegraph explore "<符号名或问题>"` 输出同 MCP。
   - 其他常用:`codegraph callers <符号>`(谁调用)/ `codegraph callees <符号>`(调用了谁)/ `codegraph impact <符号>`(改动影响面)/ `codegraph search <名>`(全文搜符号,FTS5)/ `codegraph files <符号>`(文件结构)。
2. **项目未索引(无 `.codegraph/`)→ 退回 `rg`/`fd`**,或先 `codegraph init` 建索引(一次性,之后自动增量同步)。
3. **非代码文件**(配置、文案、proto、md)或**已知文件路径精读**:直接 Read/Grep/Glob,不走 CodeGraph。

## Bash 内 grep/find 注意

Claude Code 把 `grep`/`find` shadow 成 zsh function,真身是 claude 二进制以 `ARGV0=ugrep`/`bfs` 跑自己(多面体二进制)。ugrep 7.5 高度兼容 GNU grep,`-E`/`-A`/`-P`/`--exclude-dir` 等常见选项**都能用**,不会乱报 bad option。

**"有时报错"的头号原因**:子进程(`bash -c`/`sh -c`/`xargs`/`find -exec sh`/`#!/bin/bash` 脚本)**不继承 zsh function**,退回系统 BSD grep/find,选项语义不同 → 冷门 GNU 长选项报错。其次:`CLAUDE_CODE_EXECPATH` 未设或 claude 二进制不可执行时,shadow fallback 到 `command grep`/`command find`(BSD 版)。

**避坑**:
- 搜文本用 `rg`、找文件用 `fd` —— 首选,绕开一切。
- 确需真 BSD 语义:`command grep` / `/usr/bin/find` 显式绕过。
- 直接敲 `ugrep`/`bfs` 走系统 brew 版,与 shadow 用的 claude 内置版可能不同。
- 带 Grep/Glob 工具的子 agent 用内置工具,不受 shell shadow 影响。

## 跨语言/跨仓库提示

- **跨语言调用链**(Swift↔ObjC、RN↔Native):CodeGraph 自动桥接,`codegraph_explore` 可追踪。
- **Flutter↔原生(Pigeon/MethodChannel)**:桥接支持未明确,查不到时退回 grep Pigeon 生成文件 + 原生 handler。
- **多仓库**:每个 repo 独立 `.codegraph/`,跨仓库查询需 cd 到对应仓库或分别索引后手动关联。
