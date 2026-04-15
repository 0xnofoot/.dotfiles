#!/usr/bin/env bash
# 批量重命名：在 $EDITOR 中列出文件，根据修改内容重命名
set -euo pipefail

tmpfile=$(mktemp /tmp/yazi-bulk-rename.XXXXXX)
trap 'rm -f "$tmpfile" "$tmpfile.orig"' EXIT

ls -1 > "$tmpfile.orig"
cp "$tmpfile.orig" "$tmpfile"

${EDITOR:-nvim} "$tmpfile"

paste -d '\n' "$tmpfile.orig" "$tmpfile" | while true; do
    IFS= read -r old || break
    IFS= read -r new || break
    [ "$old" = "$new" ] && continue
    [ -z "$new" ] && continue
    mv -- "$old" "$new"
done
