#!/usr/bin/env python3
"""Install lock PAM into ~/.config/tanjun/pam. Refuse world/group-writable files."""
from __future__ import annotations

import os
import stat
import sys
from pathlib import Path

NAMES = ("password.conf", "fingerprint.conf")


def world_or_group_writable(path: Path) -> bool:
    try:
        mode = path.stat().st_mode
    except OSError:
        return False
    return bool(mode & (stat.S_IWGRP | stat.S_IWOTH))


def install(src_dir: Path, dest_dir: Path) -> Path | None:
    src_dir = Path(src_dir)
    dest_dir = Path(dest_dir)
    if dest_dir.exists() and dest_dir.is_dir() and world_or_group_writable(dest_dir):
        return None
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest_dir.chmod(0o700)
    for name in NAMES:
        src = src_dir / name
        dest = dest_dir / name
        if not src.is_file():
            return None
        if dest.exists() and world_or_group_writable(dest):
            return None
        dest.write_bytes(src.read_bytes())
        dest.chmod(0o600)
    return dest_dir


def main() -> int:
    if len(sys.argv) < 2:
        return 1
    cmd = sys.argv[1]
    if cmd != "install" or len(sys.argv) < 4:
        return 1
    got = install(Path(sys.argv[2]), Path(sys.argv[3]))
    if got is None:
        return 2
    sys.stdout.write(f"{got}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
