#!/bin/bash
# 自己实现 floax-style popup toggle，不调 floax.sh 的原因：
# 1. floax.sh 在 toggle-off 分支用 `display-message -p '#{session_name}'` 判断是否
#    在 popup 里，状态一污染（scratch 被外部先 kill 再重建等）就会误把主客户端
#    识别成 scratch，打下去的 detach-client 会把主会话干掉
# 2. floax.sh 每次 popup 打开都会 set_bindings 把 C-M-s/b/f/r/e/d/u 注册到 root，
#    我们不想要这些 chord，还得额外 unbind，反复折腾
# 3. floax.sh 初次创建 scratch 用 `new-session -c $(pane_current_path)`，popup 第一次
#    打开会落在调用目录，即使关了 @floax-change-path 也无效
# 这里自己处理，保留 @floax-width/@floax-height/@floax-border-color/@floax-title 四个
# 配置兼容原插件的文档化 knob，缩放仍走 tmux-floax/scripts/zoom-options.sh
set -e

SESSION="scratch"

# 先捕获调用方会话名 —— 必须在任何 tmux 修改动作之前。下面 new-session -d 会让
# tmux 把 scratch 记为"最近使用"会话，再调 display-message 就会返回 scratch，
# 拿这个值 setenv 给 zoom-options.sh 的 ORIGIN_SESSION 用就等于 popup 和 origin
# 互相比自己尺寸，永远判"超限"，M-+ 不放大
CALLER_SESSION="$(tmux display-message -p '#{session_name}')"

# 在 popup 里按 M-f → toggle 关闭
if [ "$CALLER_SESSION" = "$SESSION" ]; then
    tmux detach-client
    exit 0
fi

# 在外面按 M-f → 确保 scratch 在 $HOME，然后 popup 出来
if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux new-session -d -c "$HOME" -s "$SESSION"
    tmux set-option -t "$SESSION" status off
fi
# scratch 销毁时 popup 客户端自动 detach（等效关 popup）
tmux set-option -t "$SESSION" detach-on-destroy on

# 把调用方会话名写进 ORIGIN_SESSION 给 zoom-options.sh resize() 用 —— 它比较
# popup 新尺寸是否超过 ORIGIN_SESSION 的 window 尺寸，超了就 return 不放大
tmux setenv -g ORIGIN_SESSION "$CALLER_SESSION"

WIDTH=$(tmux show-option -gqv '@floax-width')
HEIGHT=$(tmux show-option -gqv '@floax-height')
BORDER=$(tmux show-option -gqv '@floax-border-color')
TITLE=$(tmux show-option -gqv '@floax-title')

tmux popup \
    ${BORDER:+-S "fg=$BORDER"} \
    ${TITLE:+-T "$TITLE"} \
    -w "${WIDTH:-80%}" \
    -h "${HEIGHT:-80%}" \
    -b rounded \
    -E \
    "tmux attach-session -t $SESSION"
