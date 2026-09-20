#!/usr/bin/env python3
"""Parse loginctl inhibitors. Block rest when idle/sleep is mode=block."""
from __future__ import annotations

import subprocess
import sys


def blocked(text: str) -> bool:
    body = (text or "").strip()
    if not body:
        return False
    for raw in body.splitlines():
        line = raw.strip()
        if not line or line.lower().startswith("who"):
            continue
        low = line.lower()
        mode = ""
        what = ""
        parts = [p.strip() for p in line.replace("|", "\t").split("\t") if p.strip()]
        if len(parts) >= 2:
            what = parts[-3].lower() if len(parts) >= 3 else ""
            mode = parts[-1].lower()
            if "what:" in low:
                continue
        if "mode: block" in low and ("idle" in low or "sleep" in low):
            return True
        if mode == "block" and ("idle" in what or "sleep" in what or "idle" in low or "sleep" in low):
            return True
    return False


def list_inhibitors() -> str:
    try:
        r = subprocess.run(
            ["loginctl", "list-inhibitors", "--no-pager"],
            check=False,
            capture_output=True,
            text=True,
            timeout=2,
        )
        return (r.stdout or "") + (r.stderr or "")
    except (OSError, subprocess.TimeoutExpired):
        return ""


def main() -> int:
    if len(sys.argv) > 1 and sys.argv[1] == "parse":
        sys.stdout.write("true\n" if blocked(sys.stdin.read()) else "false\n")
        return 0
    sys.stdout.write("true\n" if blocked(list_inhibitors()) else "false\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
