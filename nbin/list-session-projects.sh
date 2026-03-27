#!/usr/bin/env bash

set -euo pipefail

roots=(
  "$HOME/source"
  "$HOME/dotfiles_ikr"
  "$HOME/nixos-config"
  "$HOME/secondBrain"
  "/bulk/cobra0/home/nclshrnk/"
  "/bulk/netserv0/wimas/nclshrnk/source"
)

for root in "${roots[@]}"; do
  [[ -d "$root" ]] || continue

  fd -H -I -u -E .venv -t f -t d '^\.git$' "$root" -x dirname
done | awk 'NF && !seen[$0]++'
