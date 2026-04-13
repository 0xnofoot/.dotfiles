#!/bin/bash
#

mime=$(file -bL --mime-type "$1")
category=${mime%%/*}
# kind=${mime##*/}

if [[ -d "$1" ]]; then
    eza -lh --icons  "$1" 2> /dev/null | head -500
elif [ "$category" = text ]; then
    bat --theme=Dracula --color=always --paging=never --style=plain "$1" 2> /dev/null | head -500
else
    exiftool "$1" 2> /dev/null | head -500
fi

