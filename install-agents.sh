#!/bin/bash
set -euo pipefail

REPODIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

npm_install_if_missing() {
  local bin="$1"
  local pkg="$2"
  if have_cmd "$bin"; then
    echo "$bin already installed: $($bin --version 2>/dev/null || echo 'unknown version')"
    return
  fi
  echo "Installing $pkg via npm..."
  npm install -g "$pkg"
}

# --- fnm + Node.js ---

ensure_node() {
  if have_cmd node && have_cmd npm; then
    echo "Node.js already installed: $(node --version)"
    return
  fi

  if ! have_cmd fnm; then
    echo "Installing fnm..."
    curl -fsSL https://fnm.vercel.app/install | bash
    export PATH="$HOME/.local/share/fnm:$PATH"
    eval "$(fnm env --shell bash)"
  fi

  echo "Installing LTS Node.js via fnm..."
  fnm install --lts
  fnm default lts-latest
}

# --- Agent CLIs ---

install_claude_code() { npm_install_if_missing claude  @anthropic-ai/claude-code; }
install_paseo()       { npm_install_if_missing paseo   @getpaseo/cli; }
install_codex()       { npm_install_if_missing codex   @openai/codex; }
install_pi()          { npm_install_if_missing pi      @mariozechner/pi-coding-agent; }
install_opencode()    { npm_install_if_missing opencode opencode-ai; }
install_oh_my_opencode() { npm_install_if_missing oh-my-opencode oh-my-opencode; }

# --- Config symlinks ---

link_claude_config() {
  mkdir -p ~/.claude
  ln -sf "$REPODIR/.claude/settings.json"    ~/.claude/settings.json
  ln -sf "$REPODIR/.claude/mcp.json"         ~/.claude/.mcp.json
  echo "Claude config linked"
}

link_paseo_config() {
  mkdir -p ~/.paseo
  ln -sf "$REPODIR/paseo/config.json" ~/.paseo/config.json
  echo "Paseo config linked"
}

link_codex_config() {
  mkdir -p ~/.codex
  ln -sf "$REPODIR/codex/config.toml" ~/.codex/config.toml
  echo "Codex config linked"
}

link_opencode_config() {
  mkdir -p ~/.opencode
  ln -sf "$REPODIR/.opencode/opencode.json" ~/.opencode/opencode.json
  echo "OpenCode config linked"
}

# --- Main ---

ensure_node

install_claude_code
install_paseo
install_codex
install_pi
install_opencode
install_oh_my_opencode

link_claude_config
link_paseo_config
link_codex_config
link_opencode_config

# Portable agent architecture symlinks (CLAUDE.md, settings.json, agents/, skills/autoresearch)
"$REPODIR/link-agents.sh"

echo ""
echo "Agent setup complete."
echo "Next steps:"
echo "  1. Run 'claude' (Sonnet-first; scout/deep-reasoner subagents auto-available)"
echo "  2. autoresearch skill is active standalone — no plugin needed"
