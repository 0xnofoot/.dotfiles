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

# 在 zsh-vi-mode 之后恢复 fzf 按键绑定并初始化 starship
# （starship 必须在此初始化，避免与 zsh-vi-mode 的
# zle-keymap-select 钩子包装冲突 — 否则会 FUNCNEST 溢出）
function zvm_after_init() {
    # 守卫：每个会话只初始化 starship 一次 — 重复 source 会叠加
    # zle-keymap-select 钩子，导致 FUNCNEST 溢出
    (( ${+functions[starship_precmd]} )) || eval "$(starship init zsh)"
    eval "$(fzf --zsh)"

    # atuin 接管 Ctrl+R 搜索历史，保留 ↑ 给 zsh-history-substring-search
    if (( ${+commands[atuin]} )); then
        eval "$(atuin init zsh --disable-up-arrow)"
    fi

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
