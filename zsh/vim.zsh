# ------------------
# zsh vi-mode config（zsh-vi-mode 钩子）
# ------------------

# 配置 — 在插件初始化之前调用
function zvm_config() {
    ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
    ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
    ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
    ZVM_OPPEND_MODE_CURSOR=$ZVM_CURSOR_UNDERLINE
    ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT
    ZVM_VI_HIGHLIGHT_BACKGROUND=#504945
    ZVM_VI_SURROUND_BINDKEY=classic
    ZVM_LAZY_KEYBINDINGS=true
}

# 加速移动 widget
remap_vi_H() { for i in {1..3}; do zle vi-backward-char; done }
zle -N remap_vi_H

remap_vi_L() { for i in {1..3}; do zle vi-forward-char; done }
zle -N remap_vi_L

remap_vi_W() { for i in {1..3}; do zle vi-forward-blank-word; done }
zle -N remap_vi_W

remap_vi_E() { for i in {1..3}; do zle vi-forward-blank-word-end; done }
zle -N remap_vi_E

remap_vi_B() { for i in {1..3}; do zle vi-backward-blank-word; done }
zle -N remap_vi_B

# 自定义 vicmd 按键绑定 — 在懒加载按键绑定时调用
function zvm_after_lazy_keybindings() {
    bindkey -M vicmd "H" remap_vi_H
    bindkey -M vicmd "L" remap_vi_L
    bindkey -M vicmd "W" remap_vi_W
    bindkey -M vicmd "E" remap_vi_E
    bindkey -M vicmd "B" remap_vi_B
    bindkey -M vicmd "," vi-beginning-of-line
    bindkey -M vicmd "." vi-end-of-line
    bindkey -M vicmd "'" vi-match-bracket
}

# 输入法自动切换 — Normal 切英文，Insert 恢复上次输入法（仅 macOS）
ZVM_PREV_IM=""
function zvm_after_select_vi_mode() {
    [[ "$OSTYPE" != darwin* ]] && return
    (( $+commands[macism] || $+commands[im-select] )) || return
    case $ZVM_MODE in
        $ZVM_MODE_NORMAL)
            ZVM_PREV_IM=$(macism 2>/dev/null)
            macism com.apple.keylayout.ABC 2>/dev/null
            ;;
        $ZVM_MODE_INSERT)
            # 切回 CJK 方向用 im-select 替代 macism：macism 在切 CJK 时会触发
            # macOS 焦点事件导致窗口闪烁，im-select 的 TIS 调用路径不会触发。
            if [[ -n "$ZVM_PREV_IM" && "$ZVM_PREV_IM" != "com.apple.keylayout.ABC" ]]; then
                if (( $+commands[im-select] )); then
                    im-select "$ZVM_PREV_IM" 2>/dev/null
                else
                    macism "$ZVM_PREV_IM" 2>/dev/null
                fi
            fi
            ;;
    esac
}

# ------------------
# 顶层初始化 — source vim.zsh 时立即 eval
# ------------------
# 不放在 zvm_after_init 里的原因：fzf 0.71+ 的 init 脚本在顶层包含无条件 return
# （0.70 及之前只有条件 return），在函数体内 eval 时 return 会让 zvm_after_init
# 提前退出，导致后续 eval（atuin 等）全部跳过。
# 顶层 eval 时 return 只退出 eval 自身，不影响后续语句。
# 各自用幂等守卫，避免 source ~/.zshrc 时重复初始化。

# starship — 自定义 flag 守卫，不依赖 starship 内部函数名
# （1.25+ 函数名前缀从 starship_ 改为 prompt_starship_，旧守卫 ${+functions[starship_precmd]} 永远失效）
[[ -n "$_STARSHIP_INITED" ]] || { eval "$(starship init zsh)"; _STARSHIP_INITED=1; }

# fzf
[[ -n "$_FZF_INITED" ]] || { eval "$(fzf --zsh)"; _FZF_INITED=1; }

# atuin 接管 Ctrl+R 搜索历史，保留 ↑ 给 zsh-history-substring-search
# 不能用 ATUIN_SESSION 做守卫：它由 atuin init 主动 export，子 shell 会继承，
# yazi 按 S 起的新 zsh 会误判已 init 从而跳过，导致 atuin-search widget
# 未注册、Ctrl+R 回退到 zsh 默认 bck-i-search。用不导出的 local flag。
if [[ -z "$_ATUIN_INITED" ]] && command -v atuin &>/dev/null; then
    eval "$(atuin init zsh --disable-up-arrow)"
    _ATUIN_INITED=1
fi

# ------------------
# zvm_after_init — 只保留必须在 zsh-vi-mode 初始化之后再做的事
# ------------------
function zvm_after_init() {
    # starship 的 zle-keymap-select widget 会被 zsh-vi-mode 的 bindkey -v 覆盖，
    # 导致 zvm_after_select_vi_mode 钩子在模式切换时不触发（状态栏不切换输入法）。
    # zvm 0.12.0 未暴露内部 widget，这里根据 zle 内置的 $KEYMAP 手动维护 ZVM_MODE
    # 并调用用户钩子，再链到 starship。函数名走 starship 1.25+ 的 prompt_ 前缀。
    if (( ${+functions[prompt_starship_zle-keymap-select]} )); then
        _zvm_starship_keymap_select() {
            case "$KEYMAP" in
                vicmd)      ZVM_MODE=$ZVM_MODE_NORMAL ;;
                main|viins) ZVM_MODE=$ZVM_MODE_INSERT ;;
            esac
            (( ${+functions[zvm_after_select_vi_mode]} )) && zvm_after_select_vi_mode
            prompt_starship_zle-keymap-select "$@"
        }
        zle -N zle-keymap-select _zvm_starship_keymap_select
    fi

    # zsh-vi-mode 会重建 viins/vicmd keymap，顶层 atuin 的 Ctrl+R 绑定会被清掉，
    # 按 atuin 18.x 的 widget 命名（按 keymap 分）在 emacs/viins 下重绑一次；
    # vicmd 下 atuin 默认用 `/` 触发，Ctrl+R 留给 fzf
    (( ${+widgets[atuin-search]} ))       && bindkey -M emacs '^R' atuin-search
    (( ${+widgets[atuin-search-viins]} )) && bindkey -M viins '^R' atuin-search-viins

    if [[ -n "$TMUX_POPUP" ]]; then
        _tmux_popup_exit() { exit }
        zle -N _tmux_popup_exit
        bindkey '\eQ' _tmux_popup_exit
        bindkey -M vicmd '\eQ' _tmux_popup_exit

        _tmux_popup_confirm_exit() {
            local reply cancelled=0
            zle -I
            trap 'cancelled=1; echo' INT
            read -k 1 "reply?kill-pane? (y/n) "
            trap - INT
            (( cancelled )) || echo
            (( ! cancelled )) && [[ "$reply" == [yY] ]] && exit
            zle clear-screen
        }
        zle -N _tmux_popup_confirm_exit
        bindkey '\eq' _tmux_popup_confirm_exit
        bindkey -M vicmd '\eq' _tmux_popup_confirm_exit
    fi
}
