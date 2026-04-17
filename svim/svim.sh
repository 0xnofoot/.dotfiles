#!/bin/bash
# Normal 模式自动切回英文输入法
# $MODE 由 SketchyVim 注入：Normal="n", Insert="", Visual="v"
if [ "$MODE" = "n" ]; then
  "$(command -v macism)" com.apple.keylayout.ABC 2>/dev/null
fi
