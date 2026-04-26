# ------------------
# alias config
# ------------------

alias x='exit'

alias ls='eza --icons'
alias la='eza -a --icons'
alias ll='eza -al --icons'
alias lg='eza -al --icons --git'

alias cd='z'
alias cdi='zi'

alias rm='trash-put'

alias v='nvim'
alias t='tmux'
alias f='fzf'
alias j='yazi'
alias b='btm'
alias jl='jless'

alias g='git'
alias gs='git status'
alias gd='git diff'
alias gc='git clone'
alias gp='git push origin'
alias gl='git log'
alias glo='git log --oneline'

alias cc='claude'
alias ccc='claude -c'
alias ccd='claude --allow-dangerously-skip-permissions'
alias cccd='claude -c --allow-dangerously-skip-permissions'

# 仅在 kitty 外层（非 tmux 包裹）直连远端时把 ssh 转给 kitten ssh —— kitten ssh 会
# 把 kitty 的 terminfo 推到远端，避免远端不识别 TERM=xterm-kitty 导致字符乱码。
# tmux 内 TERM 已被重写为 tmux-256color，远端普遍支持，不需要转发
if [[ "$TERM" == "xterm-kitty" ]] && [[ -z "$TMUX" ]] && command -v kitten &>/dev/null; then
    alias ssh='kitten ssh'
fi

# ------------------
# functions
# ------------------

# jless 包装 — 自动识别 JSONC（扩展名 .jsonc/.json5 或含 //、/* 注释、尾逗号），
# strip 后喂给真 jless；普通 JSON 透传。真命令用 `command jless` 调。
jless() {
  # 字符串上下文感知：先匹配完整 JSON 字符串（含转义），再剥离 // 和 /* */ 注释，
  # 最后去掉尾逗号。避免把字符串内容里的 // 当成注释切掉。
  local _strip='s{("(?:[^"\\]|\\.)*")|/\*.*?\*/|//[^\n]*}{defined $1 ? $1 : ""}ges; s{,(\s*[\]\}])}{$1}g'
  if (( $# == 0 )); then
    # 无参数且 stdin 是终端 → 没有输入可读，直接交给 jless 报错/显示帮助
    if [[ -t 0 ]]; then
      command jless
      return
    fi
    # 管道输入：用 >| 绕开 NO_CLOBBER，强制写入 mktemp 预建文件
    local tmp; tmp=$(mktemp); cat >| "$tmp"
    if grep -qE '(^|[^:"])//|/\*' "$tmp"; then
      perl -0pe "$_strip" "$tmp" | command jless -
    else
      command jless "$tmp"
    fi
    rm -f "$tmp"
    return
  fi
  local file="${@: -1}"
  if [[ -f "$file" ]] && { [[ "$file" == *.jsonc || "$file" == *.json5 ]] || grep -qE '(^|[^:"])//|/\*' "$file"; }; then
    perl -0pe "$_strip" "$file" | command jless -
  else
    command jless "$@"
  fi
}
