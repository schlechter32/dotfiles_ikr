#!/bin/bash

selected="$({
  tv \
    --ansi \
    --source-command="rg --color=always --line-number --no-heading --smart-case --glob '!04archive' --glob '!06referencenotes' --glob '!extrepos' '' ~/secondBrain"
} )" || exit 0

[ -n "$selected" ] || exit 0

plain=$(printf '%s' "$selected" | perl -pe 's/\e\[[0-9;]*m//g')
file=${plain%%:*}
rest=${plain#*:}
line=${rest%%:*}

exec nvim "$file" "+$line"
