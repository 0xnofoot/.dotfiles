#!/usr/bin/env bash
# Bulk rename: lists files in $EDITOR, then renames based on changes
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
