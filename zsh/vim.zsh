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

# Restore fzf keybindings after zsh-vi-mode init
function zvm_after_init() {
    eval "$(fzf --zsh)"
}
