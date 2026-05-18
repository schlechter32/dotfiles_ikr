# Personal global instructions

## Model routing
- Default to working directly on the main Sonnet thread; token efficiency matters.
- Delegate codebase search/location to the `scout` subagent (Haiku): it returns
  ranked paths + summaries, never file dumps.
- For genuinely hard reasoning (subtle bugs, races, architecture), delegate to the
  `deep-reasoner` subagent (Opus) and hand it the specific files scout found.
  Opus must not scan the repo itself.
- Use Opus only when explicitly needed; never default subagents to Opus.

## Verification
- Verify before claiming completion; if it fails, keep iterating.
