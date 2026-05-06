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
# zvm_after_init — 只保留必须在 zsh-vi-mode 初始化之后再做的事
# ------------------
# starship/fzf/atuin 的顶层 init 已迁到 optimization.zsh，此处钩子依赖那些
# 初始化产生的 widget / prompt 函数存在（source 顺序：env → optimization →
# vim → plugs，zvm_after_init 在 zsh-vi-mode 加载时触发，此时上面都已完成）
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

    # atuin 18.x 的 widget 按 keymap 分名（atuin-search/atuin-search-viins/
    # atuin-search-vicmd），用 Alt+/ 触发；zsh-vi-mode 会重建 viins/vicmd
    # keymap，所以 viins/vicmd 必须在这里重绑，emacs 顶层绑过也顺便统一
    (( ${+widgets[atuin-search]} ))       && bindkey -M emacs '\e/' atuin-search
    (( ${+widgets[atuin-search-viins]} )) && bindkey -M viins '\e/' atuin-search-viins
    (( ${+widgets[atuin-search-vicmd]} )) && bindkey -M vicmd '\e/' atuin-search-vicmd

    # 禁用 ^R —— atuin 走 M-/，不需要 fzf 的 fzf-history-widget，也不想回落到
    # zsh 默认 history-incremental-search-backward（bck-i-search）。绑 noop 吃掉即可
    _noop_widget() { : }
    zle -N _noop_widget
    bindkey -M emacs '^R' _noop_widget
    bindkey -M viins '^R' _noop_widget
    bindkey -M vicmd '^R' _noop_widget

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
