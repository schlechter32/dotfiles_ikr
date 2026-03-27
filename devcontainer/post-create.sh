#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[devcontainer] %s\n' "$*"
}

export HOME="${HOME:-/home/dev}"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/nbin:$PATH"
mkdir -p "$HOME/.local/bin" "$HOME/.ssh"

if [ -d "$HOME/dotfiles" ] && [ -x "$HOME/dotfiles/install.sh" ]; then
  log 'applying dotfiles in container mode'
  "$HOME/dotfiles/install.sh" --container
fi
