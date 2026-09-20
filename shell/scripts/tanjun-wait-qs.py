#!/usr/bin/env python3
"""Watch a Quickshell log until load succeeds or fails. Exit 0 only on load."""
from __future__ import annotations

import sys
import time
from pathlib import Path


def verdict(text: str) -> str:
    body = text or ""
    if "Failed to load configuration" in body:
        return "fail"
    if "Configuration Loaded" in body:
        return "ok"
    return ""


def alive(pid: int) -> bool:
    if pid <= 0:
        return True
    try:
        Path(f"/proc/{pid}").stat()
        return True
    except OSError:
        return False


def wait_log(path: Path, pid: int = 0, timeout: float = 8.0) -> str:
    deadline = time.time() + timeout
    offset = 0
    buf = ""
    while time.time() < deadline:
        try:
            with path.open("rb") as f:
                f.seek(offset)
                chunk = f.read()
            if chunk:
                offset += len(chunk)
                buf += chunk.decode("utf-8", errors="replace")
        except OSError:
            pass
        got = verdict(buf)
        if got:
            return got
        if pid > 0 and not alive(pid):
            return verdict(buf) or "fail"
        time.sleep(0.05)
    return "fail"


def main() -> int:
    if len(sys.argv) < 2:
        return 1
    path = Path(sys.argv[1])
    pid = int(sys.argv[2]) if len(sys.argv) > 2 and sys.argv[2].isdigit() else 0
    timeout = float(sys.argv[3]) if len(sys.argv) > 3 else 8.0
    return 0 if wait_log(path, pid, timeout) == "ok" else 1


if __name__ == "__main__":
    raise SystemExit(main())
