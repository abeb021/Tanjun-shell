from __future__ import annotations

import json
import py_compile
import shutil
import subprocess
from pathlib import Path

from lib import COMP, PALETTE_KEYS, ROOT, SCRIPTS, SHELL, run


def _luac(path: Path) -> subprocess.CompletedProcess:
    return run(["luac", "-p", str(path)])


def register(s) -> None:
    palettes = sorted((SHELL / "themes").rglob("*.json"))
    s.ok("palette files", len(palettes) >= 9, f"count {len(palettes)}")
    names = []
    for p in palettes:
        try:
            data = json.loads(p.read_text(encoding="utf-8"))
            err = ""
        except json.JSONDecodeError as e:
            data = {}
            err = str(e)
        s.ok(f"palette json {p.stem}", not err, err)
        names.append(data.get("name"))
        for key in PALETTE_KEYS:
            s.ok(f"palette {p.stem}.{key}", key in data, f"missing {key}")
        s.eq(f"palette {p.stem} kind folder", data.get("kind"), p.parent.name)
        s.eq(f"palette {p.stem} name file", data.get("name"), p.stem)
        for key in ("accent", "bg", "fg", "surface"):
            val = str(data.get(key, ""))
            s.ok(f"palette {p.stem}.{key} hex", val.startswith("#") and len(val) in (4, 7, 9), val)
    s.ok("monochrome present", "monochrome" in names)
    s.ok("mocha present", "mocha" in names)

    cfg_path = Path.home() / ".config" / "tanjun" / "config.json"
    if cfg_path.is_file():
        try:
            cfg = json.loads(cfg_path.read_text(encoding="utf-8"))
            err = ""
        except json.JSONDecodeError as e:
            cfg = None
            err = str(e)
        s.ok("user config.json", isinstance(cfg, dict) and not err, err or "not an object")
        if isinstance(cfg, dict):
            clock = cfg.get("clock")
            if clock is not None:
                s.ok("config.clock object", isinstance(clock, dict), str(type(clock)))
                zones = (clock or {}).get("zones")
                if zones is not None:
                    s.ok("config.clock.zones list", isinstance(zones, list), str(type(zones)))
                    for i, z in enumerate(zones or []):
                        s.ok(f"config.zone[{i}] id", isinstance(z, dict) and "id" in z, str(z))
            services = cfg.get("services")
            if services is not None:
                s.ok("config.services object", isinstance(services, dict), str(type(services)))
            screens = cfg.get("screens")
            if screens is not None:
                s.ok("config.screens object", isinstance(screens, dict), str(type(screens)))
                if "gamma" in (screens or {}):
                    s.ok("config.screens.gamma int", isinstance(screens["gamma"], int), str(screens["gamma"]))
            appearance = cfg.get("appearance")
            if appearance is not None:
                s.ok("config.appearance object", isinstance(appearance, dict), str(type(appearance)))
                if isinstance(appearance, dict) and "style" in appearance:
                    s.ok(
                        "config.appearance.style chrome",
                        appearance["style"] in ("tanjun", "panel", ""),
                        str(appearance["style"]),
                    )
    else:
        s.ok("user config.json omitted", True)

    luac = shutil.which("luac")
    s.ok("luac on PATH", bool(luac), "luac missing")
    if luac:
        lua_files = sorted((COMP / "hyprland").rglob("*.lua"))
        s.ok("hypr lua files", len(lua_files) > 5, f"count {len(lua_files)}")
        for p in lua_files:
            r = _luac(p)
            s.ok(f"luac {p.relative_to(ROOT)}", r.returncode == 0, (r.stderr or r.stdout or "")[-300:])

    niri = shutil.which("niri")
    s.ok("niri on PATH", bool(niri), "niri missing")
    if niri:
        kdl = COMP / "niri" / "config.kdl"
        r = run(["niri", "validate", "-c", str(kdl)])
        s.ok("niri validate repo", r.returncode == 0, ((r.stderr or "") + (r.stdout or ""))[-500:])

    for script in (
        SHELL / "scripts" / "tanjun-paint.py",
        SHELL / "scripts" / "tanjun-host.py",
        ROOT / "tests" / "run.py",
    ):
        s.exists(script)
        try:
            py_compile.compile(str(script), doraise=True)
            err = ""
        except py_compile.PyCompileError as e:
            err = str(e)
        s.ok(f"py_compile {script.relative_to(ROOT)}", not err, err)

    s.exists(SCRIPTS / "setup.sh")
    s.exists(SHELL / "shell.qml")
    s.exists(SHELL / "services" / "qmldir")
