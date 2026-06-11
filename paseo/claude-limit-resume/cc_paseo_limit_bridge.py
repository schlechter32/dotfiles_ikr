#!/usr/bin/env python3
# pyright: reportExplicitAny=false, reportAny=false, reportUnknownVariableType=false, reportUnknownMemberType=false, reportUnknownArgumentType=false, reportOptionalMemberAccess=false, reportUnusedCallResult=false, reportImplicitStringConcatenation=false, reportUnusedParameter=false
"""Deterministic Claude Code quota reset resume bridge for Paseo.

This file intentionally has no third-party dependencies.  It is used in two
roles:

* hook:   Claude Code StopFailure hook writes a marker and schedules one wakeup.
* runner: the wakeup resumes the interrupted session through Paseo when possible,
          otherwise through Claude Code's CLI.
"""

from __future__ import annotations

import argparse
import datetime as dt
import email.utils
import hashlib
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any


APP_NAME = "cc-paseo-limit-resume"
DEFAULT_DELAY_SECONDS = int(os.environ.get("CC_PASEO_LIMIT_DEFAULT_DELAY_SECONDS", "3600"))
LIMIT_WINDOW_HOURS = float(os.environ.get("CC_PASEO_LIMIT_WINDOW_HOURS", "5"))
SAFETY_BUFFER_SECONDS = int(os.environ.get("CC_PASEO_LIMIT_SAFETY_BUFFER_SECONDS", "120"))
MAX_BACKOFF_SECONDS = int(os.environ.get("CC_PASEO_LIMIT_MAX_BACKOFF_SECONDS", "21600"))

LIMIT_PATTERNS = [
    re.compile(pattern, re.IGNORECASE)
    for pattern in [
        r"subscription\s+quota\s+exceeded",
        r"quota\s+(?:exceeded|exhausted)",
        r"limit\s+exhausted",
        r"usage\s+quota",
        r"rate\s+limit",
        r"too\s+many\s+requests",
        r"resource\s+exhausted",
        r"insufficient[_\s-]*quota",
        r"payment\s+required",
        r"billing",
        r"try\s+again\s+later",
    ]
]


def utc_now() -> dt.datetime:
    return dt.datetime.now(dt.timezone.utc)


def parse_iso(value: str) -> dt.datetime:
    normalized = value.strip().replace("Z", "+00:00")
    parsed = dt.datetime.fromisoformat(normalized)
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=dt.datetime.now().astimezone().tzinfo)
    return parsed.astimezone(dt.timezone.utc)


def state_dir() -> Path:
    configured = os.environ.get("CC_PASEO_LIMIT_STATE_DIR")
    if configured:
        return Path(configured).expanduser()
    base = os.environ.get("XDG_STATE_HOME")
    if base:
        return Path(base).expanduser() / APP_NAME
    return Path.home() / ".local" / "state" / APP_NAME


def read_stdin_json() -> dict[str, Any]:
    raw = sys.stdin.read()
    if not raw.strip():
        return {}
    try:
        parsed = json.loads(raw)
    except json.JSONDecodeError:
        return {"raw_stdin": raw}
    return parsed if isinstance(parsed, dict) else {"stdin": parsed}


def flatten_strings(value: Any) -> list[str]:
    result: list[str] = []
    if isinstance(value, str):
        result.append(value)
    elif isinstance(value, dict):
        for item in value.values():
            result.extend(flatten_strings(item))
    elif isinstance(value, list):
        for item in value:
            result.extend(flatten_strings(item))
    return result


def contains_limit_signal(text: str) -> bool:
    return any(pattern.search(text) for pattern in LIMIT_PATTERNS)


def parse_http_date(text: str) -> dt.datetime | None:
    try:
        parsed = email.utils.parsedate_to_datetime(text.strip())
    except (TypeError, ValueError):
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=dt.timezone.utc)
    return parsed.astimezone(dt.timezone.utc)


def parse_relative_delay(text: str, now: dt.datetime) -> dt.datetime | None:
    retry_after = re.search(r"retry-after\s*[:=]\s*(\d{1,8})", text, re.IGNORECASE)
    if retry_after:
        return now + dt.timedelta(seconds=int(retry_after.group(1)))

    generic_after = re.search(
        r"(?:try\s+again\s+in|resets?\s+in|reset\s+in|wait)\s+"
        r"(\d+(?:\.\d+)?)\s*(seconds?|secs?|s|minutes?|mins?|m|hours?|hrs?|h|days?|d)\b",
        text,
        re.IGNORECASE,
    )
    if not generic_after:
        return None
    amount = float(generic_after.group(1))
    unit = generic_after.group(2).lower()
    multiplier = 1
    if unit.startswith(("min", "m")):
        multiplier = 60
    elif unit.startswith(("hour", "hr", "h")):
        multiplier = 3600
    elif unit.startswith(("day", "d")):
        multiplier = 86400
    return now + dt.timedelta(seconds=int(amount * multiplier))


def parse_absolute_reset(text: str, now: dt.datetime) -> dt.datetime | None:
    # ISO-ish timestamps and common provider messages:
    # "reset at 2026-05-20 15:43:27", "will reset at 2026-05-11 01:20:12 +0800 CST"
    reset_at = re.search(
        r"(?:reset(?:s)?|reset\s+time|will\s+reset|limit\s+will\s+reset)\s+(?:at|on)?\s*"
        r"(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}(?::\d{2})?(?:\s*(?:Z|[+-]\d{2}:?\d{2})?)?)",
        text,
        re.IGNORECASE,
    )
    if reset_at:
        value = reset_at.group(1).strip()
        compact_tz = re.sub(r"([+-]\d{2})(\d{2})$", r"\1:\2", value)
        try:
            return parse_iso(compact_tz.replace(" ", "T", 1))
        except ValueError:
            pass

    # "Retry-After: Wed, 11 Jun 2026 12:00:00 GMT"
    http_match = re.search(r"retry-after\s*[:=]\s*([^\n\r]+)", text, re.IGNORECASE)
    if http_match:
        parsed = parse_http_date(http_match.group(1))
        if parsed:
            return parsed

    # Time-only reset. Treat as local time today/tomorrow.
    time_only = re.search(r"(?:reset(?:s)?|try\s+again)\s+(?:at|after)\s+(\d{1,2}:\d{2})(?::\d{2})?", text, re.IGNORECASE)
    if time_only:
        local_tz = dt.datetime.now().astimezone().tzinfo
        hour, minute = [int(part) for part in time_only.group(1).split(":")]
        candidate = dt.datetime.now(local_tz).replace(hour=hour, minute=minute, second=0, microsecond=0)
        if candidate <= dt.datetime.now(local_tz):
            candidate += dt.timedelta(days=1)
        return candidate.astimezone(dt.timezone.utc)

    return None


def compute_retry_at(payload: dict[str, Any], attempt: int) -> tuple[dt.datetime, str]:
    now = utc_now()
    text = "\n".join(flatten_strings(payload))
    parsed = parse_absolute_reset(text, now) or parse_relative_delay(text, now)
    if parsed:
        return parsed + dt.timedelta(seconds=SAFETY_BUFFER_SECONDS), "parsed-reset"
    delay = min(DEFAULT_DELAY_SECONDS * (2 ** max(attempt - 1, 0)), MAX_BACKOFF_SECONDS)
    return now + dt.timedelta(seconds=delay), "default-backoff"


def marker_id(payload: dict[str, Any]) -> str:
    session = str(payload.get("session_id") or payload.get("sessionId") or "unknown-session")
    transcript = str(payload.get("transcript_path") or payload.get("transcriptPath") or "")
    digest = hashlib.sha256(f"{session}\0{transcript}".encode()).hexdigest()[:12]
    return re.sub(r"[^A-Za-z0-9_.-]+", "-", session)[:48] + "-" + digest


def load_existing_marker(path: Path) -> dict[str, Any] | None:
    if not path.exists():
        return None
    try:
        data = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        return None
    return data if isinstance(data, dict) else None


def build_resume_prompt(marker: dict[str, Any]) -> str:
    return (
        "The Claude Code provider/session limit should have reset. "
        "Continue the interrupted task from the current repository/session state. "
        "Do not restart from scratch; inspect the existing context/transcript if needed."
        f"\n\nBridge marker: {marker.get('id')}"
        f"\nClaude session: {marker.get('session_id') or 'unknown'}"
        f"\nTranscript path: {marker.get('transcript_path') or 'unknown'}"
    )


def scheduler_env() -> dict[str, str]:
    env = os.environ.copy()
    env.setdefault("PATH", "/usr/local/bin:/usr/bin:/bin:" + str(Path.home() / ".local" / "bin"))
    return env


def run_quiet(cmd: list[str], *, input_text: str | None = None, timeout: int = 20) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        input=input_text,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=timeout,
        env=scheduler_env(),
        check=False,
    )


def cron_tag(marker: Path) -> str:
    return f"# {APP_NAME}:{marker.stem}"


def bridge_script_path() -> Path:
    return Path(__file__).resolve()


def portable_runner_command(marker: Path) -> str:
    script = bridge_script_path()
    try:
        script_str = "$HOME/" + str(script.relative_to(Path.home()))
    except ValueError:
        script_str = shlex.quote(str(script))
    return f"python3 {script_str} run --marker {shlex.quote(str(marker))}"


def schedule_systemd(marker: Path, retry_at: dt.datetime) -> str | None:
    if not shutil.which("systemd-run"):
        return None
    check = run_quiet(["systemctl", "--user", "is-system-running"], timeout=5)
    if check.returncode not in (0, 1):
        return None
    unit = re.sub(r"[^A-Za-z0-9_.-]+", "-", f"{APP_NAME}-{marker.stem}")[:200]
    when = retry_at.astimezone(dt.timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    cmd = [
        "systemd-run",
        "--user",
        "--collect",
        f"--unit={unit}",
        f"--on-calendar={when}",
        "/bin/sh",
        "-lc",
        portable_runner_command(marker),
    ]
    result = run_quiet(cmd)
    if result.returncode == 0:
        return "systemd-user"
    # A transient timer from an earlier scheduling pass is still pending.
    if "already exists" in result.stderr:
        return "systemd-user"
    return None


def schedule_at(marker: Path, retry_at: dt.datetime) -> str | None:
    if not shutil.which("at"):
        return None
    local = retry_at.astimezone()
    at_time = local.strftime("%Y%m%d%H%M.%S")
    command = portable_runner_command(marker) + "\n"
    result = run_quiet(["at", "-t", at_time], input_text=command)
    if result.returncode == 0:
        return "at"
    return None


def remove_cron_entry(marker: Path) -> None:
    if not shutil.which("crontab"):
        return
    current = run_quiet(["crontab", "-l"])
    if current.returncode not in (0, 1):
        return
    tag = cron_tag(marker)
    lines = [line for line in current.stdout.splitlines() if tag not in line]
    run_quiet(["crontab", "-"], input_text="\n".join(lines) + ("\n" if lines else ""))


def schedule_cron(marker: Path, retry_at: dt.datetime) -> str | None:
    if not shutil.which("crontab"):
        return None
    local = retry_at.astimezone()
    current = run_quiet(["crontab", "-l"])
    if current.returncode not in (0, 1):
        return None
    tag = cron_tag(marker)
    kept = [line for line in current.stdout.splitlines() if tag not in line]
    command = f"{portable_runner_command(marker)} {tag}"
    entry = f"{local.minute} {local.hour} {local.day} {local.month} * {command}"
    updated = "\n".join(kept + [entry]) + "\n"
    result = run_quiet(["crontab", "-"], input_text=updated)
    if result.returncode == 0:
        return "cron"
    return None


def schedule_marker(marker: Path, retry_at: dt.datetime) -> str:
    if os.environ.get("CC_PASEO_LIMIT_SCHEDULER") == "none":
        return "disabled"
    method = schedule_systemd(marker, retry_at) or schedule_at(marker, retry_at) or schedule_cron(marker, retry_at)
    if not method:
        raise RuntimeError("No supported scheduler found: need systemd --user, at, or crontab")
    return method


def command_exists(name: str) -> str | None:
    return shutil.which(name)


def json_contains(value: Any, needle: str) -> bool:
    if not needle:
        return False
    if isinstance(value, str):
        return needle in value
    if isinstance(value, dict):
        return any(json_contains(item, needle) for item in value.values())
    if isinstance(value, list):
        return any(json_contains(item, needle) for item in value)
    return False


def infer_paseo_agent_id(marker: dict[str, Any]) -> str | None:
    paseo_home = Path(os.environ.get("PASEO_HOME", str(Path.home() / ".paseo"))).expanduser()
    agents_dir = paseo_home / "agents"
    if not agents_dir.exists():
        return None
    needles = [
        str(marker.get("session_id") or ""),
        str(marker.get("transcript_path") or ""),
        str(marker.get("cwd") or ""),
    ]
    candidates: list[tuple[float, str]] = []
    for path in agents_dir.rglob("*.json"):
        try:
            data = json.loads(path.read_text())
        except (OSError, json.JSONDecodeError):
            continue
        if any(json_contains(data, needle) for needle in needles):
            agent_id = str(data.get("id") or data.get("agentId") or path.stem)
            try:
                mtime = path.stat().st_mtime
            except OSError:
                mtime = 0
            candidates.append((mtime, agent_id))
    if not candidates:
        return None
    return sorted(candidates, reverse=True)[0][1]


def resume_with_paseo(marker: dict[str, Any]) -> subprocess.CompletedProcess[str] | None:
    paseo = command_exists(os.environ.get("PASEO_CLI", "paseo"))
    agent_id = marker.get("paseo_agent_id") or os.environ.get("PASEO_AGENT_ID") or infer_paseo_agent_id(marker)
    if not paseo or not agent_id:
        return None
    return run_quiet([paseo, "send", str(agent_id), build_resume_prompt(marker)], timeout=120)


def resume_with_claude(marker: dict[str, Any]) -> subprocess.CompletedProcess[str] | None:
    claude = command_exists(os.environ.get("CLAUDE_CLI", "claude"))
    session_id = marker.get("session_id")
    if not claude or not session_id:
        return None
    # -p/--print is supported by Claude Code for non-interactive prompt submission.
    return run_quiet([claude, "--resume", str(session_id), "--print", build_resume_prompt(marker)], timeout=600)


def write_marker(payload: dict[str, Any]) -> Path | None:
    text = "\n".join(flatten_strings(payload))
    if text and not contains_limit_signal(text):
        return None

    directory = state_dir()
    markers = directory / "markers"
    markers.mkdir(parents=True, exist_ok=True)
    mid = marker_id(payload)
    path = markers / f"{mid}.json"
    existing = load_existing_marker(path) or {}
    # Already pending with a wakeup in the future: leave it alone so repeated
    # scans/hooks don't inflate the attempt counter or double-schedule.
    pending_retry = parse_timestamp(existing.get("retry_at"))
    if pending_retry and pending_retry > utc_now():
        return None
    attempt = int(existing.get("attempt", 0)) + 1
    retry_at, reason = compute_retry_at(payload, attempt)

    marker = {
        "id": mid,
        "created_at": existing.get("created_at") or utc_now().isoformat(),
        "updated_at": utc_now().isoformat(),
        "attempt": attempt,
        "retry_at": retry_at.isoformat(),
        "retry_reason": reason,
        "session_id": payload.get("session_id") or payload.get("sessionId"),
        "transcript_path": payload.get("transcript_path") or payload.get("transcriptPath"),
        "cwd": payload.get("cwd") or os.getcwd(),
        "paseo_agent_id": payload.get("paseo_agent_id") or os.environ.get("PASEO_AGENT_ID") or os.environ.get("PASEO_AGENT"),
        "hook_event_name": payload.get("hook_event_name") or payload.get("hookEventName"),
        "last_error_excerpt": text[:4000],
        "raw_payload": payload,
    }
    tmp = path.with_suffix(".tmp")
    tmp.write_text(json.dumps(marker, indent=2, sort_keys=True) + "\n")
    tmp.replace(path)
    method = schedule_marker(path, retry_at)
    marker["scheduler"] = method
    tmp.write_text(json.dumps(marker, indent=2, sort_keys=True) + "\n")
    tmp.replace(path)
    return path


def write_marker_from_rate_cache(cache_path: Path) -> Path | None:
    cache = load_existing_marker(cache_path)
    if not cache:
        return None
    try:
        r5 = int(cache.get("r5", 0))
        resets_at = int(str(cache.get("r5_resets_at", "0")))
    except (TypeError, ValueError):
        return None
    if r5 < 100 or resets_at <= int(utc_now().timestamp()):
        return None
    reset = dt.datetime.fromtimestamp(resets_at, tz=dt.timezone.utc)
    cwd = str(cache.get("cwd") or Path.home())
    session = "claude-rate-limit-" + hashlib.sha256(cwd.encode()).hexdigest()[:12]
    payload = {
        "hook_event_name": "RateCacheScan",
        "session_id": session,
        "cwd": cwd,
        "error": {
            "message": "Claude Code rate limit/session limit detected from ~/.claude/rate-cache.json; "
            f"usage={r5}%; reset at {reset.isoformat()}",
        },
        "rate_cache": cache,
    }
    return write_marker(payload)


def paseo_agents_root() -> Path:
    return Path(os.environ.get("PASEO_HOME", str(Path.home() / ".paseo"))).expanduser() / "agents"


def iter_paseo_agent_files(root: Path) -> list[Path]:
    if not root.exists():
        return []
    return sorted(path for path in root.rglob("*.json") if path.is_file())


def parse_timestamp(value: object) -> dt.datetime | None:
    if not isinstance(value, str) or not value:
        return None
    try:
        return parse_iso(value)
    except ValueError:
        return None


def is_recent_agent(agent: dict[str, Any], since: dt.datetime) -> bool:
    for key in ("lastActivityAt", "updatedAt", "lastUserMessageAt", "createdAt"):
        parsed = parse_timestamp(agent.get(key))
        if parsed and parsed >= since:
            return True
    return False


def agent_provider(agent: dict[str, Any]) -> str:
    runtime = agent.get("runtimeInfo") if isinstance(agent.get("runtimeInfo"), dict) else {}
    persistence = agent.get("persistence") if isinstance(agent.get("persistence"), dict) else {}
    return str(runtime.get("provider") or persistence.get("provider") or agent.get("provider") or "")


def agent_session_id(agent: dict[str, Any]) -> str:
    runtime = agent.get("runtimeInfo") if isinstance(agent.get("runtimeInfo"), dict) else {}
    persistence = agent.get("persistence") if isinstance(agent.get("persistence"), dict) else {}
    return str(runtime.get("sessionId") or persistence.get("sessionId") or agent.get("id") or "unknown")


def build_paseo_agent_limit_payload(agent: dict[str, Any], cache: dict[str, Any], resets_at: int, r5: int) -> dict[str, Any]:
    reset = dt.datetime.fromtimestamp(resets_at, tz=dt.timezone.utc)
    agent_id = str(agent.get("id") or agent_session_id(agent))
    cwd = str(agent.get("cwd") or cache.get("cwd") or Path.home())
    title = str(agent.get("title") or "Paseo Claude agent")
    return {
        "hook_event_name": "PaseoAgentRateCacheScan",
        "session_id": agent_session_id(agent),
        "cwd": cwd,
        "paseo_agent_id": agent_id,
        "error": {
            "message": "Claude Code rate limit/session limit detected for Paseo agent; "
            f"usage={r5}%; reset at {reset.isoformat()}; agent={agent_id}; title={title}",
        },
        "rate_cache": cache,
        "paseo_agent": {
            "id": agent_id,
            "title": title,
            "status": agent.get("lastStatus"),
            "provider": agent_provider(agent),
            "cwd": cwd,
            "updatedAt": agent.get("updatedAt"),
            "lastActivityAt": agent.get("lastActivityAt"),
        },
    }


def write_markers_from_paseo_agents(cache_path: Path, *, since_hours: float) -> list[Path]:
    cache = load_existing_marker(cache_path)
    if not cache:
        return []
    try:
        r5 = int(cache.get("r5", 0))
        resets_at = int(str(cache.get("r5_resets_at", "0")))
    except (TypeError, ValueError):
        return []
    if r5 < 100 or resets_at <= int(utc_now().timestamp()):
        return []

    # Only agents active inside the current limit window were plausibly
    # interrupted by it; --since-hours stays as an additional cap.
    window_start = dt.datetime.fromtimestamp(resets_at, tz=dt.timezone.utc) - dt.timedelta(hours=LIMIT_WINDOW_HOURS)
    since = max(window_start, utc_now() - dt.timedelta(hours=since_hours))
    written: list[Path] = []
    for path in iter_paseo_agent_files(paseo_agents_root()):
        agent = load_existing_marker(path)
        if not agent:
            continue
        if agent.get("archivedAt"):
            continue
        if agent_provider(agent) != "claude":
            continue
        if str(agent.get("lastStatus") or "") not in {"idle", "running", "error"}:
            continue
        if not is_recent_agent(agent, since):
            continue
        try:
            marker = write_marker(build_paseo_agent_limit_payload(agent, cache, resets_at, r5))
        except RuntimeError as exc:
            print(f"could not schedule marker for agent {agent.get('id')}: {exc}", file=sys.stderr)
            continue
        if marker:
            written.append(marker)
    return written


def cmd_hook(_args: argparse.Namespace) -> int:
    payload = read_stdin_json()
    try:
        path = write_marker(payload)
    except Exception as exc:  # Hook output is ignored for StopFailure; log only.
        log_dir = state_dir() / "logs"
        log_dir.mkdir(parents=True, exist_ok=True)
        with (log_dir / "hook-errors.log").open("a") as fh:
            fh.write(f"{utc_now().isoformat()} {exc}\n")
        return 0
    if path:
        print(f"scheduled quota resume marker: {path}")
    return 0


def run_marker(marker_path: Path) -> int:
    remove_cron_entry(marker_path)
    marker = load_existing_marker(marker_path)
    if not marker:
        return 0
    retry_at = parse_iso(str(marker["retry_at"]))
    if retry_at > utc_now() + dt.timedelta(seconds=30):
        method = schedule_marker(marker_path, retry_at)
        marker["scheduler"] = method
        marker_path.write_text(json.dumps(marker, indent=2, sort_keys=True) + "\n")
        return 0

    attempts = [resume_with_paseo, resume_with_claude]
    result: subprocess.CompletedProcess[str] | None = None
    for attempt in attempts:
        result = attempt(marker)
        if result is None:
            continue
        if result.returncode == 0:
            done_dir = state_dir() / "done"
            done_dir.mkdir(parents=True, exist_ok=True)
            marker["completed_at"] = utc_now().isoformat()
            marker["last_command_stdout"] = result.stdout[-4000:]
            (done_dir / marker_path.name).write_text(json.dumps(marker, indent=2, sort_keys=True) + "\n")
            marker_path.unlink(missing_ok=True)
            return 0
        combined = f"{result.stdout}\n{result.stderr}"
        if contains_limit_signal(combined):
            marker["raw_payload"] = {"retry_failure": combined}
            marker["last_error_excerpt"] = combined[-4000:]
            marker["attempt"] = int(marker.get("attempt", 0)) + 1
            retry_at, reason = compute_retry_at(marker, int(marker["attempt"]))
            marker["retry_at"] = retry_at.isoformat()
            marker["retry_reason"] = f"runner-{reason}"
            marker["updated_at"] = utc_now().isoformat()
            marker_path.write_text(json.dumps(marker, indent=2, sort_keys=True) + "\n")
            method = schedule_marker(marker_path, retry_at)
            marker["scheduler"] = method
            marker_path.write_text(json.dumps(marker, indent=2, sort_keys=True) + "\n")
            return 0
        break

    fail_dir = state_dir() / "failed"
    fail_dir.mkdir(parents=True, exist_ok=True)
    marker["failed_at"] = utc_now().isoformat()
    if result:
        marker["last_command_returncode"] = result.returncode
        marker["last_command_stdout"] = result.stdout[-4000:]
        marker["last_command_stderr"] = result.stderr[-4000:]
    else:
        marker["last_command_stderr"] = "No resume command was available. Install paseo CLI or claude CLI, or export PASEO_AGENT_ID."
    (fail_dir / marker_path.name).write_text(json.dumps(marker, indent=2, sort_keys=True) + "\n")
    marker_path.unlink(missing_ok=True)
    return 1


def cmd_run(args: argparse.Namespace) -> int:
    return run_marker(Path(args.marker).expanduser())


def sweep_due_markers() -> list[Path]:
    """Run markers whose retry time has passed but whose one-shot wakeup was
    lost (e.g. transient systemd timers do not survive a reboot)."""
    markers = state_dir() / "markers"
    if not markers.exists():
        return []
    swept: list[Path] = []
    for path in sorted(markers.glob("*.json")):
        data = load_existing_marker(path)
        if not data:
            continue
        retry = parse_timestamp(str(data.get("retry_at") or ""))
        if retry and retry <= utc_now():
            run_marker(path)
            swept.append(path)
    return swept


def cmd_status(_args: argparse.Namespace) -> int:
    root = state_dir()
    for bucket in ["markers", "done", "failed"]:
        directory = root / bucket
        print(f"{bucket}:")
        if not directory.exists():
            print("  (none)")
            continue
        for path in sorted(directory.glob("*.json")):
            data = load_existing_marker(path) or {}
            print(f"  {path.name} retry_at={data.get('retry_at')} attempt={data.get('attempt')}")
    return 0


def cmd_scan(args: argparse.Namespace) -> int:
    # "Nothing to do" is the normal state; always exit 0 so the systemd
    # service does not show as failed on every tick.
    for path in sweep_due_markers():
        print(f"ran past-due resume marker: {path.name}")
    cache_path = Path(args.rate_cache).expanduser()
    if args.paseo_agents:
        paths = write_markers_from_paseo_agents(cache_path, since_hours=float(args.since_hours))
        for path in paths:
            print(f"scheduled quota resume marker from Paseo agent state: {path}")
        if not paths:
            print("no new limited Paseo Claude agents found")
        return 0
    path = write_marker_from_rate_cache(cache_path)
    if path:
        print(f"scheduled quota resume marker from global rate cache: {path}")
    else:
        print("no new Claude session-limit reset found in rate cache")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)
    hook = sub.add_parser("hook", help="Run as Claude Code StopFailure hook")
    hook.set_defaults(func=cmd_hook)
    run = sub.add_parser("run", help="Run a scheduled retry marker")
    run.add_argument("--marker", required=True)
    run.set_defaults(func=cmd_run)
    status = sub.add_parser("status", help="List pending/done/failed markers")
    status.set_defaults(func=cmd_status)
    scan = sub.add_parser("scan", help="Detect Claude Code session limit from local rate cache")
    scan.add_argument("--rate-cache", default=str(Path.home() / ".claude" / "rate-cache.json"))
    scan.add_argument("--paseo-agents", action="store_true", default=True, help="Create one marker per recent limited Paseo Claude agent")
    scan.add_argument("--global-marker", dest="paseo_agents", action="store_false", help="Create one global marker instead of per-agent markers")
    scan.add_argument("--since-hours", default="24", help="Only consider Paseo Claude agents active within this many hours")
    scan.set_defaults(func=cmd_scan)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    return int(args.func(args))


if __name__ == "__main__":
    raise SystemExit(main())
