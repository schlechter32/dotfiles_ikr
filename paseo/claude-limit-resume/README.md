# Paseo + Claude Code limit-reset resume bridge

This is a no-fork bridge for continuing a Paseo-launched Claude Code session after
the Claude subscription/session/provider limit resets.

It is deterministic: it does **not** call an AI every 10–15 minutes.  The Claude
Code `StopFailure` hook writes a marker and schedules one OS wakeup at the parsed
reset time.  If no reset time is present, it uses a configurable backoff timer.

## Files

- `cc_paseo_limit_bridge.py` — hook, scheduler, and retry runner.
- `install.py` — merges the Claude Code hook into `~/.claude/settings.json`.

## Install on this machine

```bash
cd ~/dotfiles_ikr/paseo/claude-limit-resume
chmod +x cc_paseo_limit_bridge.py install.py
./install.py
./install.py --install-timer
```

The installer backs up `~/.claude/settings.json` before changing it.
`--install-timer` installs a user systemd timer that runs the deterministic Paseo
agent scanner every minute. It does not call an AI; it only reads local Paseo
agent state plus `~/.claude/rate-cache.json` and creates one-shot resume markers
when a reset time is known.  The same timer also acts as a watchdog: it runs any
marker whose retry time has passed, so resumes survive reboots (transient
`systemd-run` timers do not).

## Move to another machine

Copy/sync your dotfiles to the new machine, then run:

```bash
cd ~/dotfiles_ikr/paseo/claude-limit-resume   # or wherever the repo lives
chmod +x cc_paseo_limit_bridge.py install.py
./install.py
./install.py --install-timer
```

That is everything.  The installer derives all paths from its own location, so
the repo can live anywhere; the hook command and the systemd unit are written
relative to `$HOME` when possible, never hardcoded to `~/dotfiles_ikr`.  Re-run
both commands after moving the repo to a different path.

No Paseo fork is required.  Requirements:

- Python 3 (stdlib only, no pip installs);
- for the per-minute scanner/watchdog: a systemd user instance
  (`systemctl --user`).  Without one, `--install-timer` prints a warning and
  skips; the hook-only mode still works through one of:
  1. `systemd-run --user` preferred,
  2. `at` fallback,
  3. `crontab` fallback.

## How scheduling works

When Claude Code hits a limit, the hook parses messages like:

- `Subscription quota exceeded. You can continue using free models.`
- `Retry-After: 3600`
- `Weekly/Monthly Limit Exhausted. Your limit will reset at 2026-05-20 15:43:27`
- `Resource exhausted: Please try again later.`

Then it writes a marker under:

```text
~/.local/state/cc-paseo-limit-resume/markers/
```

and schedules exactly one retry.  The retry runner attempts:

1. `paseo send <PASEO_AGENT_ID> ...` if the environment exposes a Paseo agent id;
2. otherwise it scans `~/.paseo/agents/*.json` for the Claude session/transcript/cwd
   and sends to the matching Paseo agent if one is found;
3. otherwise `claude --resume <session_id> --print ...`.

If the retry still hits a limit, the runner reschedules itself based on the new
reset time or exponential backoff.  If the retry succeeds, the marker is moved to
`~/.local/state/cc-paseo-limit-resume/done/`.  Non-limit failures are moved to
`failed/` for inspection.

## Status

```bash
~/dotfiles_ikr/paseo/claude-limit-resume/cc_paseo_limit_bridge.py status
```

Manual Paseo-agent scan:

```bash
~/dotfiles_ikr/paseo/claude-limit-resume/cc_paseo_limit_bridge.py scan --paseo-agents
```

Manual send test for a pending marker:

```bash
~/dotfiles_ikr/paseo/claude-limit-resume/cc_paseo_limit_bridge.py send-now <marker-file-or-prefix>
```

Example:

```bash
~/dotfiles_ikr/paseo/claude-limit-resume/cc_paseo_limit_bridge.py send-now e4628caa
```

## Tuning

Environment variables:

- `CC_PASEO_LIMIT_STATE_DIR` — override state directory.
- `CC_PASEO_LIMIT_DEFAULT_DELAY_SECONDS` — default retry delay if no reset time is present. Default: `3600`.
- `CC_PASEO_LIMIT_SAFETY_BUFFER_SECONDS` — extra delay after parsed reset time. Default: `180`.
- `CC_PASEO_LIMIT_MAX_BACKOFF_SECONDS` — maximum fallback backoff. Default: `21600`.
- `CC_PASEO_LIMIT_SCHEDULER=none` — testing only; write markers without creating OS timers.
- `CC_PASEO_LIMIT_WINDOW_HOURS` — length of the provider limit window; the scanner
  only resumes Paseo agents active inside the current window. Default: `5`.
- `PASEO_CLI` — override `paseo` command path.
- `CLAUDE_CLI` — override `claude` command path.

## Important limits

This cannot bypass Claude's subscription/session limit.  It only waits until the
reset time and retries automatically.  Paseo send is best-effort because Claude
Code hook payloads do not always expose a Paseo agent id; in that case the bridge
infers the agent from local Paseo state or falls back to Claude Code resume.
