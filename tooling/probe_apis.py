#!/usr/bin/env python3
"""
Read-only API schema probe for DT-PocketHR.

Calls ONLY safe GET endpoints using a test Bearer token from the environment,
strips all personal/sensitive values into pure JSON type schemas, writes
docs/api_schemas_live.json, and reports schema drift vs the previous snapshot.

Usage:
  export POCKET_HR_TOKEN="<bearer-jwt>"
  export POCKET_HR_TENANT="domex"        # optional, default: domex
  export POCKET_HR_USER_ID="<uid>"       # optional, auto-detected from /auth/me
  python3 tooling/probe_apis.py
"""

from __future__ import annotations

import datetime
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

DEFAULT_BASE_URL = "https://api.human.go.digitable.io/human/v2/api"
OUTPUT_PATH = Path(__file__).resolve().parent.parent / "docs" / "api_schemas_live.json"


def infer_schema(value: Any, depth: int = 0) -> Any:
    """Convert a live JSON payload into a PII-free structural type schema."""
    if depth > 8:
        return "any"
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "boolean"
    if isinstance(value, int):
        return "integer"
    if isinstance(value, float):
        return "number"
    if isinstance(value, str):
        return "string"
    if isinstance(value, list):
        if not value:
            return ["empty"]
        # Merge schemas across up to first 5 elements so optional keys are captured
        merged = infer_schema(value[0], depth + 1)
        for item in value[1:5]:
            merged = merge_schemas(merged, infer_schema(item, depth + 1))
        return [merged]
    if isinstance(value, dict):
        return {str(k): infer_schema(v, depth + 1) for k, v in sorted(value.items())}
    return type(value).__name__


def merge_schemas(a: Any, b: Any) -> Any:
    if a == b:
        return a
    if isinstance(a, dict) and isinstance(b, dict):
        out = dict(a)
        for k, v in b.items():
            out[k] = merge_schemas(out[k], v) if k in out else v
        return dict(sorted(out.items()))
    if isinstance(a, list) and isinstance(b, list) and a and b:
        return [merge_schemas(a[0], b[0])]
    if a == "null":
        return f"{b}|null" if isinstance(b, str) else b
    if b == "null":
        return f"{a}|null" if isinstance(a, str) else a
    if isinstance(a, str) and isinstance(b, str):
        parts = sorted(set(a.split("|")) | set(b.split("|")))
        return "|".join(parts)
    return a


def diff_schemas(old: Any, new: Any, prefix: str = "") -> list[str]:
    changes: list[str] = []
    if type(old) is not type(new):
        changes.append(f"  ~ {prefix or '<root>'}: {type(old).__name__} -> {type(new).__name__}")
        return changes
    if isinstance(old, dict):
        old_keys, new_keys = set(old.keys()), set(new.keys())
        for k in sorted(new_keys - old_keys):
            changes.append(f"  + {prefix}.{k}" if prefix else f"  + {k}")
        for k in sorted(old_keys - new_keys):
            changes.append(f"  - {prefix}.{k}" if prefix else f"  - {k}")
        for k in sorted(old_keys & new_keys):
            p = f"{prefix}.{k}" if prefix else k
            changes.extend(diff_schemas(old[k], new[k], p))
    elif isinstance(old, list):
        if old and new:
            changes.extend(diff_schemas(old[0], new[0], f"{prefix}[]"))
    elif old != new:
        changes.append(f"  ~ {prefix}: {old} -> {new}")
    return changes


def fetch_get(url: str, token: str, tenant: str = "") -> tuple[int, Any]:
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/json",
        "Device-Time": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "User-Agent": "DT-PocketHR-SchemaProbe/1.0",
    }
    if tenant:
        headers["Tenant"] = tenant
    req = urllib.request.Request(url, method="GET", headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
            try:
                return resp.status, json.loads(raw)
            except json.JSONDecodeError:
                return resp.status, {"_non_json_content_type": resp.headers.get("Content-Type", "")}
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8", errors="replace")[:300]
        return e.code, {"_http_error": raw}
    except Exception as e:
        return 0, {"_exception": str(e)}


def extract_uid(me_payload: Any) -> str:
    if not isinstance(me_payload, dict):
        return ""
    for container in (me_payload.get("data"), me_payload.get("user"), me_payload):
        if isinstance(container, dict):
            for key in ("_id", "id", "user_id", "uid", "employee_id"):
                val = container.get(key)
                if val is not None and str(val).strip():
                    return str(val).strip()
    return ""


def main() -> int:
    token = os.environ.get("POCKET_HR_TOKEN", "").strip()
    if not token:
        print("Error: set POCKET_HR_TOKEN environment variable to a valid Bearer JWT.", file=sys.stderr)
        return 2

    base_url = os.environ.get("POCKET_HR_BASE_URL", DEFAULT_BASE_URL).rstrip("/")
    tenant = os.environ.get("POCKET_HR_TENANT", "domex").strip()
    uid = os.environ.get("POCKET_HR_USER_ID", "").strip()

    now = datetime.datetime.now(datetime.timezone.utc)
    month = f"{now.month:02d}"
    year = str(now.year)
    today_iso = now.strftime("%Y-%m-%d")

    results: dict[str, Any] = {
        "_meta": {
            "generated_at_utc": now.isoformat(),
            "base_url": base_url,
            "tenant": tenant,
            "note": "Auto-generated PII-free structural schemas from read-only GET endpoints.",
        },
        "endpoints": {},
    }

    # 1. Probe /auth/me first so we can auto-discover uid if not provided
    me_url = f"{base_url}/auth/me?{urllib.parse.urlencode({'tenant': tenant})}"
    status, me_body = fetch_get(me_url, token, tenant)
    print(f"GET /auth/me -> HTTP {status}")
    results["endpoints"]["GET /auth/me"] = {
        "status": status,
        "schema": infer_schema(me_body),
    }
    if not uid and status == 200:
        uid = extract_uid(me_body)
        if uid:
            print(f"  (auto-detected user_id from /auth/me)")

    # 2. Remaining read-only GET endpoints
    endpoints: list[tuple[str, str]] = [
        ("GET /attendance/mobile-summary", f"{base_url}/attendance/mobile-summary?date={today_iso}&tenant={tenant}"),
        ("GET /leave", f"{base_url}/leave?tenant={tenant}" + (f"&userIds={uid}" if uid else "")),
        ("GET /todos", f"{base_url}/todos?tenant={tenant}"),
        ("GET /teams/my-team", f"{base_url}/teams/my-team?tenant={tenant}"),
        ("GET /teams/my-team/leaves", f"{base_url}/teams/my-team/leaves?tenant={tenant}"),
        ("GET /teams/my-team/attendance", f"{base_url}/teams/my-team/attendance?tenant={tenant}"),
    ]

    if uid:
        endpoints.extend([
            ("GET /leave/balance", f"{base_url}/leave/balance?userId={uid}&tenant={tenant}"),
            ("GET /leave/apply-eligibility/{uid}", f"{base_url}/leave/apply-eligibility/{uid}?tenant={tenant}"),
            ("GET /attendance/user/{tenant}/{uid}/", f"{base_url}/attendance/user/{tenant}/{uid}/?tenant={tenant}&month={month}&year={year}"),
            ("GET /variables/variables/{uid}", f"{base_url}/variables/variables/{uid}?tenant={tenant}"),
            ("GET /debts/{uid}", f"{base_url}/debts/{uid}?tenant={tenant}"),
            ("GET /payroll/salary-slips/user/{uid}", f"{base_url}/payroll/salary-slips/user/{uid}?tenant={tenant}&year={year}"),
            ("GET /teams/locations-by-userid/{uid}", f"{base_url}/teams/locations-by-userid/{uid}"),
        ])
    else:
        print("Warning: user_id not available; skipping {uid}-scoped endpoints.", file=sys.stderr)

    for label, url in endpoints:
        st, body = fetch_get(url, token, tenant)
        print(f"{label:42s} -> HTTP {st}")
        results["endpoints"][label] = {
            "status": st,
            "schema": infer_schema(body),
        }

    # 3. Compare against previous snapshot if present
    if OUTPUT_PATH.exists():
        try:
            previous = json.loads(OUTPUT_PATH.read_text(encoding="utf-8"))
            changes = diff_schemas(previous.get("endpoints", {}), results["endpoints"])
            if changes:
                print("\nSchema drift detected since last snapshot:")
                for c in changes:
                    print(c)
            else:
                print("\nNo schema drift detected.")
        except Exception as e:
            print(f"\nCould not diff previous snapshot: {e}", file=sys.stderr)

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(json.dumps(results, indent=2) + "\n", encoding="utf-8")
    print(f"\nWrote PII-free schema snapshot to {OUTPUT_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
