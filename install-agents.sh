#!/bin/bash
set -euo pipefail

REPODIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

# --- fnm + Node.js ---

ensure_node() {
  if have_cmd node && have_cmd npm; then
    echo "Node.js already installed: $(node --version)"
    return
  fi

  if have_cmd fnm; then
    echo "fnm found, installing LTS Node.js..."
    fnm install --lts
    fnm default lts-latest
  else
    echo "Installing fnm..."
    curl -fsSL https://fnm.vercel.app/install | bash
    export PATH="$HOME/.local/share/fnm:$PATH"
    eval "$(fnm env --shell bash)"
    echo "Installing LTS Node.js via fnm..."
    fnm install --lts
    fnm default lts-latest
  fi
}

# --- Claude Code CLI ---

install_claude_code() {
  if have_cmd claude; then
    echo "Claude Code already installed: $(claude --version 2>/dev/null || echo 'unknown version')"
    return
  fi

  echo "Installing Claude Code via npm..."
  npm install -g @anthropic-ai/claude-code
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

ensure_node
install_claude_code
link_claude_config
link_paseo_config
setup_omc

echo ""
echo "Agent setup complete."
echo "Next steps:"
echo "  1. Run 'claude' to start a session (OMC plugin installs automatically)"
echo "  2. Say 'setup omc' to generate HUD and CLAUDE.md"
