#!/usr/bin/env bash
# PreToolUse(Bash) 提醒：结构性代码查询应优先 codebase-memory MCP，而非 grep/find/rg。
# 仅警告、绝不阻断（任何情况都 exit 0）。命中时通过 additionalContext 把提醒注入模型上下文。
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)
[ -z "$cmd" ] && exit 0

# 命令词位置（行首 / 管道 / 分号 / & / 反引号 / 括号 / 空白后）出现 grep/find/rg 等才提醒，
# 避免把路径里的 "ripgrep"、文件名里的 "find" 等误判。
if printf '%s' "$cmd" | /usr/bin/grep -Eq '(^|[|&;`([:space:]])(grep|egrep|fgrep|rg|ag|ack|find)([[:space:]]|$)'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      additionalContext: "提醒：结构性代码查询（查找符号定义/引用、调用链、影响面、死代码、架构）应优先使用 codebase-memory MCP 工具（search_code / search_graph / trace_path / query_graph / get_code_snippet / get_architecture）。仅当项目未索引、或搜索的是非代码文本/日志/配置时，才退回 grep/find/rg。"
    }
  }'
fi
exit 0
