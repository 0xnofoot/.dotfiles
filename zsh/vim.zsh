# ------------------
# zsh vi-mode config (zsh-vi-mode hooks)
# ------------------

# Configuration — called before plugin init
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

# Accelerated movement widgets
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

# Custom vicmd keybindings — called when lazy keybindings load
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

# Restore fzf keybindings and init starship after zsh-vi-mode
# (starship must be initialized here so it doesn't conflict with
# zsh-vi-mode's zle-keymap-select hook wrapping — avoids FUNCNEST overflow)
function zvm_after_init() {
    # Guard: only init starship once per session — re-sourcing would wrap
    # zle-keymap-select on top of itself, causing FUNCNEST overflow
    (( ${+functions[starship_precmd]} )) || eval "$(starship init zsh)"
    eval "$(fzf --zsh)"

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
