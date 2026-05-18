---
name: autoresearch
description: Stateful single-mission improvement loop with strict evaluator contract, markdown decision logs, and max-runtime stop behavior. Standalone — no plugin required.
---

<Purpose>
Autoresearch is a stateful skill for bounded, evaluator-driven iterative improvement. It owns one mission at a time, keeps iterating through non-passing results, records each evaluation and decision as durable artifacts, and stops only when an explicit max-runtime ceiling or another explicit terminal condition is reached.
</Purpose>

<Use_When>
- You have a single mission with an evaluator and want persistent, strict iterative improvement
- You need durable experiment logs you can resume
- You want a periodic rerun via Claude Code native cron
</Use_When>

<Do_Not_Use_When>
- No mission/evaluator exists yet — run the Setup step below first
- You need multiple missions orchestrated together — out of scope (single-mission only)
</Do_Not_Use_When>

<Setup>
This skill assumes a mission and an evaluator already exist. If they do not, create them by hand (this replaces the former `deep-interview --autoresearch` step):

1. Create `.research/<mission-slug>/mission.md` describing, concretely:
   - the single goal
   - the artifact(s) under change
   - hard constraints / out-of-scope
   - the explicit pass condition in plain language

2. Create an evaluator: a script or command that, when run, prints **only** a JSON object to stdout:
   ```json
   { "pass": false, "score": 0.0 }
   ```
   - `pass` (boolean) is REQUIRED.
   - `score` (number) is OPTIONAL and used for trend tracking.
   - The evaluator must be deterministic and runnable non-interactively.

3. Record the evaluator invocation in `.research/<mission-slug>/evaluator.json`:
   ```json
   { "command": "bash evaluator.sh", "cwd": "." }
   ```
</Setup>

<Contract>
- Single-mission only.
- The evaluator is authoritative. Its output must be structured JSON with required boolean `pass` and optional numeric `score`.
- Non-passing iterations do **not** stop the run.
- Stop conditions are explicit and bounded, with max-runtime as the primary strict stop hook.
</Contract>

<Required_Artifacts>
Canonical persistent storage lives under `.research/<mission-slug>/`.

```text
.research/<mission-slug>/
  mission.md
  evaluator.json
  runs/<run-id>/
    evaluations/
      iteration-0001.json
      iteration-0002.json
    decision-log.md
```
Reuse existing run artifacts rather than duplicating them.
</Required_Artifacts>

<Workflow>
1. Confirm a single mission and evaluator exist (run Setup if not).
2. Establish run state and record:
   - mission slug/dir
   - evaluator reference
   - iteration count
   - started/updated timestamps
   - explicit max-runtime or deadline
3. On every iteration:
   - run exactly one experiment/change cycle
   - run the evaluator
   - persist machine-readable evaluation JSON under `runs/<run-id>/evaluations/`
   - append a human-readable markdown entry to `decision-log.md`
   - continue even when evaluation does not pass
4. Stop when:
   - the max-runtime ceiling is reached
   - the user explicitly cancels
   - another explicit terminal condition is recorded
</Workflow>

<Cron_Integration>
Claude Code native cron is the supported periodic-rerun integration point.
- one mission per scheduled job
- preserve the same mission/evaluator contract
- append new run artifacts rather than overwriting prior experiments
</Cron_Integration>

<Execution_Policy>
- Do not create multi-mission orchestration.
- Keep decision logs useful to humans, not only machines.
- Treat max-runtime as a hard stop, not a suggestion.
</Execution_Policy>
