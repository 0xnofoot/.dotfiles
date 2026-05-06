# ------------------
# zsh 启动性能优化 — 集中管理所有缓存 / 懒加载逻辑
# ------------------
# 源顺序：env.zsh (设置 PATH) → optimization.zsh (本文件) → vim.zsh (zvm hooks)
# 本文件依赖 env.zsh 已导出 HOMEBREW PATH 等，使 ${commands[$cmd]} 能查到
# 二进制。跨平台：所有工具查找都用 ${commands[]}，未装则静默跳过，不报错。

# ------------------
# 缓存目录
# ------------------
_ZSH_CACHE_DIR="$HOME/.cache/zsh"
[[ -d "$_ZSH_CACHE_DIR" ]] || mkdir -p "$_ZSH_CACHE_DIR"

# ------------------
# _zsh_cache_eval: 按二进制 mtime + init 参数指纹缓存 `tool init` 输出
# ------------------
# 每次启动 `eval "$(tool init zsh)"` 都要 fork 外部进程拿 stdout，
# starship/fzf/atuin/zoxide 加起来约 ~100ms。本函数把输出缓存到
# $_ZSH_CACHE_DIR/<name>.zsh，失效条件：
#   (1) brew upgrade 更新了 bin 的 mtime
#   (2) init 参数变了（如 atuin 调整了 --disable-* flag）
# 参数指纹以 `# args: ...` 写在缓存首行，启动时用 zsh 内建 read 取首行
# 做字符串比对，不引入子进程。
#
# 用法：_zsh_cache_eval <cmd> <cache_file> <args...>
#
# 关键点（踩坑留存）：
# 1. 不加 emulate -L — 它隐式启用 local_options，会让 fzf/atuin init
#    里的 setopt 随函数退出被回滚，破坏补全/高亮行为
# 2. 用 `${commands[$cmd]}` 而非 `command -v` — 前者直接读 zsh 内部
#    PATH 哈希，不需要子进程，而且结果是绝对路径便于和缓存文件做 mtime 比较
# 3. `>|` 覆盖重定向，NOCLOBBER 下也能工作；失败时删掉空/坏缓存避免
#    下次启动 source 到垃圾数据
_zsh_cache_eval() {
    local cmd=$1 cache=$2
    shift 2
    local bin=${commands[$cmd]}
    [[ -z "$bin" ]] && return 1
    local args_sig="# args: $*"
    local first_line=""
    [[ -s "$cache" ]] && IFS= read -r first_line < "$cache" 2>/dev/null
    if [[ ! -s "$cache" || "$bin" -nt "$cache" || "$first_line" != "$args_sig" ]]; then
        { print -r -- "$args_sig"; "$cmd" "$@" } >| "$cache" || { rm -f "$cache"; return 1; }
        # 重建缓存后异步 zcompile 生成 .zwc 字节码，下次启动 source 直接
        # 读字节码省掉 reparse；本次启动 source 仍走 .zsh，不阻塞
        zcompile -U "$cache" 2>/dev/null &!
    fi
    source "$cache"
}

# _zsh_zcompile_refresh: 对用户 zsh 脚本做 stale-check，.zwc 缺失或过期
# 则异步重建。fzf init 缓存脚本 677 行，编译后解析快 ~3-5ms；用户侧
# env/vim/optimization 加起来能再省 ~5-10ms。整批文件在一个后台子 shell
# 里顺序编译 —— 每个 &! 都是一次 fork，拆开执行反而把 fork 成本（~2ms/次）
# 重新加回启动耗时
_zsh_zcompile_refresh() {
    local -a files=("$@")
    {
        local f
        for f in "${files[@]}"; do
            [[ -f "$f" && ( ! -f "$f.zwc" || "$f" -nt "$f.zwc" ) ]] && zcompile -U "$f" 2>/dev/null
        done
    } &!
}

# ------------------
# 工具 init 缓存 — 所有工具都从 Brewfile 安装，macOS/Linux 二进制路径
# 一致，无需分平台分支。顺序和原 env.zsh/vim.zsh 保持一致。
# ------------------

# zoxide（cd 增强）
_zsh_cache_eval zoxide "$_ZSH_CACHE_DIR/zoxide.zsh" init zsh

# starship（prompt）
# 自定义 flag 守卫，不依赖 starship 内部函数名
# （1.25+ 函数名前缀从 starship_ 改为 prompt_starship_，
# 旧守卫 ${+functions[starship_precmd]} 永远失效）
[[ -n "$_STARSHIP_INITED" ]] || {
    _zsh_cache_eval starship "$_ZSH_CACHE_DIR/starship.zsh" init zsh
    _STARSHIP_INITED=1
}

# fzf（模糊搜索）
[[ -n "$_FZF_INITED" ]] || {
    _zsh_cache_eval fzf "$_ZSH_CACHE_DIR/fzf.zsh" --zsh
    _FZF_INITED=1
}

# atuin（历史搜索 — Alt+/ 触发）
# 不能用 ATUIN_SESSION 做守卫：它由 atuin init 主动 export，子 shell
# 会继承，yazi 按 S 起的新 zsh 会误判已 init 从而跳过导致 widget 未注册。
# 用不导出的 local flag。
if [[ -z "$_ATUIN_INITED" ]] && (( ${+commands[atuin]} )); then
    _zsh_cache_eval atuin "$_ZSH_CACHE_DIR/atuin.zsh" init zsh --disable-up-arrow --disable-ctrl-r
    _ATUIN_INITED=1
fi

# ------------------
# RVM — 仅在安装了 RVM 的机器上生效（macOS 开发机）
# ------------------
# Version manager 必须分两层加载：
#
#   1) PATH 段 eager — shell 启动时就把 manager 托管的 bin 摆到 /usr/bin 之前。
#      shebang 链（`#!/usr/bin/env ruby`）、GUI 子进程、launchd/CI 这些场景
#      绕过 shell function 直接查 PATH；若 RVM 的 ruby bin 不在 /usr/bin 之前，
#      `env ruby` 会命中系统 /usr/bin/ruby 2.6（macOS 自带，已 EOL）而崩溃。
#      2026-04-27 pod install 踩坑的根因就是这一段从 eager 退化成 lazy。
#
#   2) manager 函数 lazy — source ~/.rvm/scripts/rvm 要 ~200ms，用户真要
#      切版本或查 rvm 信息时才触发即可。stub 用 "unset self + source 真实
#      rvm + 以原参重放" 的手法，zsh 命令解析在执行时发生（非 parse 时），
#      重放会命中 source 后的新定义（RVM 函数 or PATH 上的真实二进制）。
#
# 未来加 nvm / pyenv / rbenv / asdf 任一个 version manager，按同样分层复制。
if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
    # eager PATH 版本选择顺序：
    #   1) ~/.rvm/environments/default symlink（rvm --default use <ver> 维护）
    #   2) fallback: ~/.rvm/rubies/ 里 mtime 最新的一个，stderr 告警
    #   3) 都没有：stderr 告警，shebang 链会命中系统 ruby
    # 不静默降级：2026-04-27 pod install 踩坑的根因就是 default 缺失时静默走
    # else 分支，ruby PATH 段未 prepend，外部进程看不到 RVM ruby
    _rvm_default="${$(readlink "$HOME/.rvm/environments/default" 2>/dev/null):t}"
    if [[ -z "$_rvm_default" || ! -d "$HOME/.rvm/rubies/$_rvm_default/bin" ]]; then
        _rvm_rubies=("$HOME"/.rvm/rubies/*(N/om))
        if (( ${#_rvm_rubies} )); then
            _rvm_default="${_rvm_rubies[1]:t}"
            print -u2 -- "[rvm] default 未设置，临时回退到 $_rvm_default；请执行 \`rvm --default use <ver>\` 固定"
        else
            _rvm_default=""
        fi
        unset _rvm_rubies
    fi
    if [[ -n "$_rvm_default" ]]; then
        export PATH="$HOME/.rvm/gems/$_rvm_default/bin:$HOME/.rvm/gems/$_rvm_default@global/bin:$HOME/.rvm/rubies/$_rvm_default/bin:$HOME/.rvm/bin:$PATH"
    else
        print -u2 -- "[rvm] 未发现任何 ~/.rvm/rubies/*，shebang \`#!/usr/bin/env ruby\` 会命中系统 ruby"
        export PATH="$PATH:$HOME/.rvm/bin"
    fi
    unset _rvm_default

    # lazy 函数 stub — 只拦 `rvm` 命令本体。ruby/gem/bundle/irb/rake/rails 等
    # 已经能通过 PATH eager 段（rubies/<ver>/bin、gems/<ver>/bin）命中真实二进制，
    # 不需要 source scripts/rvm；一并 stub 只会让首次 `ruby -v` 白付 200ms 的
    # RVM 重初始化开销（且每开一个新 shell 都会触发一次）。
    rvm() {
        unset -f rvm
        source "$HOME/.rvm/scripts/rvm"
        rvm "$@"
    }
fi

# ------------------
# 延迟加载插件 — 用 zsh-defer 把 ZLE widget 式插件推迟到首个 prompt 之后
# ------------------
# fast-syntax-highlighting / zsh-autosuggestions / zsh-autopair 都是挂 zle 钩子
# 的插件，加起来 source 期间约 ~20-25ms。延迟到 precmd 后加载只影响"第一条
# 命令"的交互（那条命令无高亮/建议/autopair），后续命令完整可用。yazi 里按 S
# 起子 shell 场景下收益显著。
#
# zsh-defer 本身由 zim 管理（zimrc 里 zmodule romkatv/zsh-defer），要在 plugs.zsh
# source init.zsh 之后才可用，所以本函数只定义、不调用；plugs.zsh 末尾负责触发。
_ZSH_DEFERRED_DIR="$HOME/.cache/zsh/deferred"

_zsh_defer_load_plugins() {
    (( $+functions[zsh-defer] )) || return
    [[ -d "$_ZSH_DEFERRED_DIR" ]] || mkdir -p "$_ZSH_DEFERRED_DIR"
    # 加载顺序：autopair / autosuggestions 先，FSH 最后（必须在 zle widget 链末端
    # 才能正确染色其他 widget 的输出）
    local -a _defs=(
        "zsh-autopair|https://github.com/hlissner/zsh-autopair.git|autopair.zsh"
        "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions.git|zsh-autosuggestions.zsh"
        "fast-syntax-highlighting|https://github.com/zdharma-continuum/fast-syntax-highlighting.git|fast-syntax-highlighting.plugin.zsh"
    )
    local entry name url file dir
    for entry in "${_defs[@]}"; do
        name=${entry%%|*}
        url=${${entry#*|}%%|*}
        file=${entry##*|}
        dir="$_ZSH_DEFERRED_DIR/$name"
        # 首次启动同步 clone（一次性 ~数秒），之后目录存在直接跳过
        [[ -d "$dir" ]] || git clone --depth 1 "$url" "$dir" &>/dev/null
        [[ -f "$dir/$file" ]] && zsh-defer source "$dir/$file"
    done
}

# ------------------
# zcompile 注册清单 — 放在文件末尾，启动所有 source 操作完成后触发异步
# 字节码生成。zim 模块自带 .zwc；这里只补齐 zim/init.zsh、用户脚本、
# _zsh_cache_eval 生成的缓存文件
# ------------------
_zsh_zcompile_refresh \
    ${ZDOTDIR:-$HOME}/.zshrc \
    $HOME/.config/zsh/env.zsh \
    $HOME/.config/zsh/optimization.zsh \
    $HOME/.config/zsh/vim.zsh \
    $HOME/.config/zsh/plugs.zsh \
    $HOME/.config/zsh/alias.zsh \
    $HOME/.config/zsh/fzf/fzf.zsh \
    $HOME/.config/zsh/local.zsh \
    $HOME/.config/zsh/zim/init.zsh \
    $_ZSH_CACHE_DIR/*.zsh(N)
