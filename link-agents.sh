#!/bin/bash
set -euo pipefail

REPODIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Portable Claude Code agent architecture:
#   - Sonnet-first main thread (personal CLAUDE.md routing)
#   - scout (Haiku) for codebase search, deep-reasoner (Opus) for hard reasoning
#   - standalone autoresearch skill (no oh-my-claudecode plugin required)
# Idempotent: safe to re-run.

link_agents() {
  mkdir -p ~/.claude/agents ~/.claude/skills

  # Personal global instructions (model routing)
  ln -sf "$REPODIR/.claude/CLAUDE.md" ~/.claude/CLAUDE.md

  # Cleaned settings.json (no OMC plugin / marketplace / statusline)
  ln -sf "$REPODIR/.claude/settings.json" ~/.claude/settings.json

  # Custom subagents
  ln -sf "$REPODIR/.claude/agents/scout.md"         ~/.claude/agents/scout.md
  ln -sf "$REPODIR/.claude/agents/deep-reasoner.md" ~/.claude/agents/deep-reasoner.md

  # Standalone autoresearch skill (whole folder so support files travel with it).
  # -n so an existing symlink-to-dir is replaced rather than nested inside.
  rmdir ~/.claude/skills/autoresearch 2>/dev/null || true
  ln -sfn "$REPODIR/.claude/skills/autoresearch" ~/.claude/skills/autoresearch

  echo "Claude agent architecture linked (CLAUDE.md, settings.json, agents/, skills/autoresearch)"
}

# User-scope MCP servers (apply to every project; reproducible across machines).
# ~/.claude.json can't be symlinked, so we re-register idempotently here instead.
register_mcps() {
  if ! command -v claude >/dev/null 2>&1; then
    echo "claude CLI not found — skipping MCP registration" >&2
    return
  fi

  # Secrets (e.g. EXA_API_KEY) come from an untracked, machine-local file.
  local secrets="${AGENT_SECRETS_FILE:-$HOME/.config/agent-secrets.env}"
  if [ -f "$secrets" ]; then
    set -a; . "$secrets"; set +a
  else
    echo "WARN: no secrets file at $secrets — exa MCP will be skipped" >&2
  fi

  # Idempotent: drop any existing user-scope entry, then (re)add.
  mcp_add() {
    local name="$1"; shift
    claude mcp remove "$name" --scope user >/dev/null 2>&1 || true
    claude mcp add "$name" --scope user "$@"
  }

  mcp_add context7 -- npx -y @upstash/context7-mcp
  mcp_add filesystem -- npx -y @modelcontextprotocol/server-filesystem "$HOME" /bulk/netserv0/wimas
  if [ -n "${EXA_API_KEY:-}" ]; then
    mcp_add exa --env "EXA_API_KEY=$EXA_API_KEY" -- npx -y exa-mcp-server
  else
    echo "WARN: EXA_API_KEY unset — skipping exa MCP" >&2
  fi

  echo "User-scope MCPs registered (context7, filesystem$([ -n "${EXA_API_KEY:-}" ] && echo ', exa'))"
}

link_agents
register_mcps
