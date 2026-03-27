#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[devcontainer] %s\n' "$*"
}

export HOME="${HOME:-/home/dev}"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/nbin:$PATH"
mkdir -p "$HOME/.local/bin" "$HOME/.ssh"

if [ -x "/workspace/install.sh" ]; then
  log 'applying live dotfiles workspace in container mode'
  /workspace/install.sh --container
fi
