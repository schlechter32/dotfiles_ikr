#!/usr/bin/env python3
# pyright: reportExplicitAny=false, reportAny=false, reportUnknownVariableType=false, reportUnknownMemberType=false, reportUnknownArgumentType=false, reportUnusedCallResult=false
"""Install the Claude Code StopFailure hook for cc-paseo-limit-resume."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import shutil
from pathlib import Path
from typing import Any


def claude_settings_path() -> Path:
    configured = os.environ.get("CLAUDE_SETTINGS_PATH")
    if configured:
        return Path(configured).expanduser()
    return Path.home() / ".claude" / "settings.json"


def load_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    with path.open() as fh:
        parsed = json.load(fh)
    if not isinstance(parsed, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return parsed


def install_hook(settings: dict[str, Any], command: str) -> bool:
    hooks = settings.setdefault("hooks", {})
    stop_failure = hooks.setdefault("StopFailure", [])
    if not isinstance(stop_failure, list):
        raise ValueError("settings.hooks.StopFailure must be an array")
    entry = {
        "matcher": "rate_limit|billing_error|authentication_failed|api_error|overloaded",
        "hooks": [{"type": "command", "command": command}],
    }
    stop_failure[:] = [
        existing
        for existing in stop_failure
        if not (
            isinstance(existing, dict)
            and any(
                isinstance(hook, dict)
                and "cc_paseo_limit_bridge.py hook" in str(hook.get("command", ""))
                for hook in existing.get("hooks", [])
            )
        )
    ]
    for existing in stop_failure:
        if isinstance(existing, dict):
            for hook in existing.get("hooks", []):
                if isinstance(hook, dict) and hook.get("command") == command:
                    return False
    stop_failure.append(entry)
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--settings", type=Path, default=claude_settings_path())
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    command = "python3 ~/dotfiles_ikr/paseo/claude-limit-resume/cc_paseo_limit_bridge.py hook"
    settings_path = args.settings.expanduser()
    settings_path.parent.mkdir(parents=True, exist_ok=True)
    settings = load_json(settings_path)
    changed = install_hook(settings, command)
    rendered = json.dumps(settings, indent=2, sort_keys=False) + "\n"
    if args.dry_run:
        print(rendered)
        return 0
    if changed and settings_path.exists():
        stamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
        shutil.copy2(settings_path, settings_path.with_suffix(settings_path.suffix + f".bak-{stamp}"))
    settings_path.write_text(rendered)
    print(f"installed StopFailure hook in {settings_path}")
    print(f"command: {command}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
