# ------------------
# plugs config
# ------------------

ZIM_HOME=${ZDOTDIR:-${HOME}}/.config/zsh/zim
# 如果缺少 zimfw 插件管理器则下载
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  if (( ${+commands[curl]} )); then
    curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  else
    mkdir -p ${ZIM_HOME} && wget -nv -O ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  fi
fi
# 安装缺失模块，如果 init.zsh 缺失或过期则更新
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZDOTDIR:-${HOME}}/.zimrc ]]; then
  source ${ZIM_HOME}/zimfw.zsh init -q
fi
# 初始化模块 — 加守卫防止重复 source ~/.zshrc 时重载 zim 模块，
# 避免 compinit 重复初始化警告
if [[ -z "$_ZSH_ZIM_LOADED" ]]; then
  _ZSH_ZIM_LOADED=1
  source ${ZIM_HOME}/init.zsh
fi
