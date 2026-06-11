#!/usr/bin/env python3
# pyright: reportExplicitAny=false, reportAny=false, reportUnknownVariableType=false, reportUnknownMemberType=false, reportUnusedCallResult=false, reportImplicitStringConcatenation=false, reportUnusedParameter=false
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


def portable_runner_command(marker: Path) -> str:
    script = "$HOME/dotfiles_ikr/paseo/claude-limit-resume/cc_paseo_limit_bridge.py"
    return f"python3 {script} run --marker {shlex.quote(str(marker))}"


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
    for path in agents_dir.glob("*.json"):
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
        "paseo_agent_id": os.environ.get("PASEO_AGENT_ID") or os.environ.get("PASEO_AGENT"),
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


def cmd_hook(_args: argparse.Namespace) -> int:
    payload = read_stdin_json()
    try:
        path = write_marker(payload)
    except Exception as exc:  # Hook output is ignored for StopFailure; log only.
        log_dir = state_dir() / "logs"
        log_dir.mkdir(parents=True, exist_ok=True)
        (log_dir / "hook-errors.log").write_text(f"{utc_now().isoformat()} {exc}\n")
        return 0
    if path:
        print(f"scheduled quota resume marker: {path}")
    return 0


def cmd_run(args: argparse.Namespace) -> int:
    marker_path = Path(args.marker).expanduser()
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
    return 1


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
    return parser


def main() -> int:
    args = build_parser().parse_args()
    return int(args.func(args))


if __name__ == "__main__":
    raise SystemExit(main())
