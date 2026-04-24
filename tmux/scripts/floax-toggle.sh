#!/bin/bash
# floax toggle wrapper：跑完 floax.sh 后立即卸掉 set_bindings 注册的 C-M-* root 绑定
# 因为 floax 的 set_bindings 在每次 popup 打开时都会把 C-M-s/b/f/r/e/d/u 注册到 server root，
# 这些 chord 全局生效、易误触且不可关闭；我们用 M-f / M-_ / M-+ / M-) 替代，所以这里把原生 chord 全干掉
~/.config/tmux/plugins/tmux-floax/scripts/floax.sh
for k in C-M-s C-M-b C-M-f C-M-r C-M-e C-M-d C-M-u; do
  tmux unbind -n "$k" 2>/dev/null
done
exit 0
