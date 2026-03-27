#!/usr/bin/env bash

set -euo pipefail

dir=${1:-}
[[ -n "$dir" ]] || exit 1

dir=${dir/#\~/$HOME}
dir=$(realpath "$dir")
name=$(basename "$dir" | tr -cs '[:alnum:]_-' '_')
name=${name#_}
name=${name%_}
[[ -n "$name" ]] || name="session"

if ! tmux has-session -t "$name" 2>/dev/null; then
  tmux new-session -d -s "$name" -c "$dir"
fi

if [[ -n "${TMUX:-}" ]]; then
  tmux switch-client -t "$name"
else
  exec tmux attach-session -t "$name"
fi
