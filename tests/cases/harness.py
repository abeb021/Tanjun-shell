from __future__ import annotations

import importlib.util
import os
import subprocess
from pathlib import Path

from lib import ROOT, QS_BIN, SHELL


def _load_wait():
    path = SHELL / "scripts" / "tanjun-wait-qs.py"
    spec = importlib.util.spec_from_file_location("tanjun_wait_qs", path)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def register(s) -> None:
    wait = _load_wait()
    s.eq("wait loaded", wait.verdict("INFO: Configuration Loaded\n"), "ok")
    s.eq(
        "wait failed load",
        wait.verdict("ERROR: Failed to load configuration\n  caused by Config.qml"),
        "fail",
    )
    s.eq("wait fail wins", wait.verdict("Failed to load configuration\nConfiguration Loaded"), "fail")
    s.eq("wait empty", wait.verdict(""), "")
    s.eq("wait noise", wait.verdict("INFO: Launching config\n"), "")

    log = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "tanjun-wait-test.log"
    log.write_text("INFO: boot\n", encoding="utf-8")
    s.eq("wait_log pending", wait.wait_log(log, timeout=0.15), "fail")
    with log.open("a", encoding="utf-8") as f:
        f.write("INFO: Configuration Loaded\n")
    s.eq("wait_log ok", wait.wait_log(log, timeout=0.5), "ok")

    hypr = ROOT / "compositors" / "hyprland" / "scripts" / "reload-shell.sh"
    niri = ROOT / "compositors" / "niri" / "scripts" / "reload-shell.sh"
    for path in (hypr, niri):
        r = subprocess.run(["bash", "-n", str(path)], check=False, capture_output=True, text=True)
        s.eq(f"reload syntax {path.name}", r.returncode, 0)

    if not QS_BIN or not os.environ.get("WAYLAND_DISPLAY"):
        return
    # qs.py boots an owned instance; this file only proves the wait helper.
