from __future__ import annotations

import os
import shutil
import subprocess

from lib import ROOT, SHELL


def register(s) -> None:
    s.exists(ROOT / "tests" / "run.sh")
    s.exists(ROOT / "tests" / "run.py")
    s.exists(ROOT / ".cursor" / "rules" / "tanjun-tests.mdc")
    qs = shutil.which("qs") or shutil.which("quickshell")
    s.ok("quickshell installed", bool(qs), "qs not on PATH")
    if not qs or os.environ.get("TANJUN_LIVE") != "1":
        return
    try:
        r = subprocess.run(
            [qs, "-p", str(SHELL)],
            check=False,
            capture_output=True,
            text=True,
            timeout=4,
        )
        out = (r.stdout or "") + (r.stderr or "")
    except subprocess.TimeoutExpired as e:
        out = ""
        if e.stdout:
            out += e.stdout if isinstance(e.stdout, str) else e.stdout.decode("utf-8", "replace")
        if e.stderr:
            out += e.stderr if isinstance(e.stderr, str) else e.stderr.decode("utf-8", "replace")
        if not out:
            out = "timeout"
    s.ok("qs config loaded", "Configuration Loaded" in out, out[-800:])
    s.lacks("qs no QtObject default property", out, "non-existent default property")
    s.lacks("qs no Singleton is not a type", out, "Singleton is not a type")
