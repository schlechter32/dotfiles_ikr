#!/usr/bin/env python3
"""
claude-usage-poll — fetch Claude rate-limit usage from Anthropic's OAuth API
and cache it for the WezTerm statusbar.

The endpoint (https://api.anthropic.com/api/oauth/usage) is hard-throttled to
roughly one call per hour (HTTP 429 with `retry-after` ~3500s). This script is
therefore self-throttling: it refuses to call the API again until
`next_allowed_at`, honouring server `retry-after` on 429. Safe to invoke as
often as you like (WezTerm calls it on a timer); it no-ops when not due.

Writes ~/.claude/usage-poll.json using the same field names as the
statusline-written ~/.claude/rate-cache.json so the WezTerm reader has a single
normalisation path. Refreshes the OAuth access token when expired.
"""

import json
import os
import sys
import time
import urllib.request
import urllib.error
import urllib.parse
from datetime import datetime, timezone

HOME = os.path.expanduser("~")
CONFIG_DIR = os.environ.get("CLAUDE_CONFIG_DIR", os.path.join(HOME, ".claude"))
CRED_PATH = os.path.join(CONFIG_DIR, ".credentials.json")
CACHE_PATH = os.path.join(CONFIG_DIR, "usage-poll.json")

USAGE_URL = "https://api.anthropic.com/api/oauth/usage"
TOKEN_URL = "https://platform.claude.com/v1/oauth/token"
# Public Claude Code OAuth client id (see oh-my-claudecode usage-api.js).
OAUTH_CLIENT_ID = os.environ.get(
    "CLAUDE_CODE_OAUTH_CLIENT_ID", "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
)

API_TIMEOUT = 10
SUCCESS_INTERVAL = 3 * 60       # don't re-poll for 3 min after a success
                                # (trial value; raise if the endpoint starts 429ing)
TRANSIENT_INTERVAL = 5 * 60     # retry sooner after a network/parse error
MAX_BACKOFF = 2 * 60 * 60       # cap any server retry-after at 2h
TOKEN_REFRESH_BUFFER_MS = 60_000


def now() -> int:
    return int(time.time())


def read_json(path):
    try:
        with open(path, "r") as f:
            return json.load(f)
    except Exception:
        return None


def atomic_write(path, obj, mode=0o600):
    tmp = f"{path}.tmp.{os.getpid()}"
    with open(tmp, "w") as f:
        json.dump(obj, f, indent=2)
    os.chmod(tmp, mode)
    os.replace(tmp, path)


def to_epoch_str(iso):
    """ISO-8601 -> unix-epoch string (matches rate-cache.json's *_resets_at)."""
    if not iso:
        return ""
    try:
        dt = datetime.fromisoformat(str(iso).replace("Z", "+00:00"))
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return str(int(dt.timestamp()))
    except Exception:
        return ""


def load_cache():
    return read_json(CACHE_PATH) or {}


def write_cache(cache):
    try:
        atomic_write(CACHE_PATH, cache)
    except Exception:
        pass


def get_oauth(creds):
    return creds.get("claudeAiOauth", creds) if isinstance(creds, dict) else {}


def refresh_token(refresh):
    body = (
        f"grant_type=refresh_token&refresh_token={urllib.parse.quote(refresh)}"
        f"&client_id={urllib.parse.quote(OAUTH_CLIENT_ID)}"
    ).encode()
    req = urllib.request.Request(
        TOKEN_URL,
        data=body,
        method="POST",
        headers={"Content-Type": "application/x-www-form-urlencoded"},
    )
    with urllib.request.urlopen(req, timeout=API_TIMEOUT) as r:
        if r.status != 200:
            return None
        d = json.loads(r.read())
    if not d.get("access_token"):
        return None
    expires_at = (
        now() * 1000 + int(d["expires_in"]) * 1000
        if d.get("expires_in")
        else d.get("expires_at")
    )
    return {
        "accessToken": d["access_token"],
        "refreshToken": d.get("refresh_token") or refresh,
        "expiresAt": expires_at,
    }


def write_back_credentials(new):
    raw = read_json(CRED_PATH)
    if not isinstance(raw, dict):
        return
    target = raw["claudeAiOauth"] if "claudeAiOauth" in raw else raw
    target["accessToken"] = new["accessToken"]
    if new.get("expiresAt") is not None:
        target["expiresAt"] = new["expiresAt"]
    if new.get("refreshToken"):
        target["refreshToken"] = new["refreshToken"]
    try:
        atomic_write(CRED_PATH, raw, mode=0o600)
    except Exception:
        pass


def get_access_token():
    creds = read_json(CRED_PATH)
    if not isinstance(creds, (dict,)):
        return None, "no_credentials"
    o = get_oauth(creds)
    token = o.get("accessToken")
    expires_at = o.get("expiresAt")
    expired = expires_at is not None and expires_at <= now() * 1000 + TOKEN_REFRESH_BUFFER_MS
    if token and not expired:
        return token, None
    refresh = o.get("refreshToken")
    if not refresh:
        return None, "auth"
    try:
        new = refresh_token(refresh)
    except Exception:
        return None, "network"
    if not new:
        return None, "auth"
    write_back_credentials(new)
    return new["accessToken"], None


def fetch_usage(token):
    req = urllib.request.Request(
        USAGE_URL,
        method="GET",
        headers={
            "Authorization": f"Bearer {token}",
            "anthropic-beta": "oauth-2025-04-20",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=API_TIMEOUT) as r:
            return r.status, json.loads(r.read()), {}
    except urllib.error.HTTPError as e:
        retry_after = e.headers.get("retry-after") if e.headers else None
        return e.code, None, {"retry_after": retry_after}
    except Exception as e:
        return None, None, {"exception": str(e)}


def parse_usage(data):
    """Anthropic response -> rate-cache.json-shaped fields."""

    def pct(node):
        try:
            v = node.get("utilization")
            return None if v is None else max(0, min(100, round(float(v))))
        except Exception:
            return None

    fh = data.get("five_hour") or {}
    sd = data.get("seven_day") or {}
    op = data.get("seven_day_opus") or {}
    out = {
        "r5": pct(fh) or 0,
        "r7": pct(sd) or 0,
        "r5_resets_at": to_epoch_str(fh.get("resets_at")),
        "r7_resets_at": to_epoch_str(sd.get("resets_at")),
    }
    opus = pct(op)
    if opus is not None:
        out["opus7"] = opus
        out["opus7_resets_at"] = to_epoch_str(op.get("resets_at"))
    return out


def main():
    cache = load_cache()
    next_allowed = cache.get("next_allowed_at", 0)
    if now() < next_allowed and "--force" not in sys.argv:
        return  # not due yet — silent no-op

    token, err = get_access_token()
    if err:
        cache.update(
            ok=False, error=err, fetched_at=now(),
            next_allowed_at=now() + TRANSIENT_INTERVAL,
        )
        write_cache(cache)
        return

    status, data, meta = fetch_usage(token)

    if status == 200 and data:
        usage = parse_usage(data)
        cache = {
            **usage,
            "ok": True,
            "ts": now(),                 # mirrors rate-cache.json's `ts`
            "fetched_at": now(),
            "last_success_at": now(),
            "rate_limited": False,
            "next_allowed_at": now() + SUCCESS_INTERVAL,
            "source": "anthropic",
        }
        write_cache(cache)
        return

    if status == 429:
        try:
            ra = int(meta.get("retry_after") or 0)
        except (TypeError, ValueError):
            ra = 0
        ra = min(ra, MAX_BACKOFF) if ra > 0 else 30 * 60
        cache.update(
            ok=False, error="rate_limited", rate_limited=True,
            fetched_at=now(), next_allowed_at=now() + ra,
        )
        write_cache(cache)
        return

    # network / unexpected: keep last good data, retry sooner
    detail = meta.get("exception") or (f"http_{status}" if status else "no_response")
    cache.update(
        ok=False, error="network", error_detail=detail, fetched_at=now(),
        next_allowed_at=now() + TRANSIENT_INTERVAL,
    )
    write_cache(cache)


if __name__ == "__main__":
    main()
