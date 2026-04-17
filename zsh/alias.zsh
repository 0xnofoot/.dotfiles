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

# ------------------
# functions
# ------------------

# jless 包装 — 自动识别 JSONC（扩展名 .jsonc/.json5 或含 //、/* 注释、尾逗号），
# strip 后喂给真 jless；普通 JSON 透传。真命令用 `command jless` 调。
jless() {
  local _strip='s{/\*.*?\*/}{}gs; s{(^|[^:"])//[^\n]*}{$1}g; s{,(\s*[\]\}])}{$1}g'
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
