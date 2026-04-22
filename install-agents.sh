#!/bin/bash
set -euo pipefail

REPODIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

# --- Claude Code CLI ---

install_claude_code() {
  if have_cmd claude; then
    echo "Claude Code already installed: $(claude --version 2>/dev/null || echo 'unknown version')"
    return
  fi

  if have_cmd npm; then
    echo "Installing Claude Code via npm..."
    npm install -g @anthropic-ai/claude-code
  else
    echo "npm not found — install Node.js first, then re-run this script"
    return 1
  fi
}

# --- Claude config symlinks ---

link_claude_config() {
  mkdir -p ~/.claude
  ln -sf "$REPODIR/claude/settings.json" ~/.claude/settings.json
  ln -sf "$REPODIR/claude/mcp.json" ~/.claude/.mcp.json
  ln -sf "$REPODIR/claude/omc-config.json" ~/.claude/.omc-config.json
  echo "Claude config linked"
}

# --- Paseo ---

link_paseo_config() {
  mkdir -p ~/.paseo
  ln -sf "$REPODIR/paseo/config.json" ~/.paseo/config.json
  echo "Paseo config linked"
}

# --- oh-my-claudecode ---

setup_omc() {
  if [[ -d ~/.claude/plugins/cache/omc ]]; then
    echo "OMC plugin already cached — will update on next claude session"
    return
  fi

  echo ""
  echo "OMC plugin will auto-install on first 'claude' session."
  echo "Run 'setup omc' inside Claude Code to complete the setup."
}

# --- Main ---

install_claude_code
link_claude_config
link_paseo_config
setup_omc

echo ""
echo "Agent setup complete."
echo "Next steps:"
echo "  1. Run 'claude' to start a session (OMC plugin installs automatically)"
echo "  2. Say 'setup omc' to generate HUD and CLAUDE.md"
