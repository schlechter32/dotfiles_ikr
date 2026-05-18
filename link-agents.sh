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

link_agents
