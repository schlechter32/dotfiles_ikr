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

if zellij list-sessions --short 2>/dev/null | grep -Fxq "$name"; then
  exec zellij attach "$name"
else
  cd "$dir"
  exec zellij -s "$name"
fi
