# ------------------
# fzf config
# ------------------

# fzf keybindings loaded via zvm_after_init in vim.zsh

export FZF_DEFAULT_OPTS='
--bind ctrl-t:top,change:top
--bind ctrl-j:down,ctrl-k:up
--bind tab:down,shift-tab:up
--preview-window right:70%
--preview "~/.config/zsh/fzf/fzf_preview.sh {}"
'
export FZF_DEFAULT_COMMAND='fd'
export FZF_COMPLETION_TRIGGER='\'
export FZF_TMUX=0
export FZF_TMUX_HEIGHT='80%'

# fzf-tab preview settings
zstyle ':fzf-tab:complete:*:*' fzf-preview '~/.config/zsh/fzf/fzf_preview.sh ${(Q)realpath}'
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview 'echo ${(P)word}'
zstyle ':fzf-tab:complete:brew-(install|uninstall|search|info):*-argument-rest' fzf-preview 'brew info $word'
zstyle ':fzf-tab:complete:tldr:argument-1' fzf-preview 'tldr --color always $word'
zstyle ':fzf-tab:complete:-command-:*' fzf-preview \
    ¦ '(out=$(tldr --color always "$word") 2>/dev/null && echo $out) || (out=$(MANWIDTH=$FZF_PREVIEW_COLUMNS man "$word") 2>/dev/null && echo $out) || (out=$(which "$word") && echo $out) || echo "${(P)word}"'

