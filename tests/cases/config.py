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
                        appearance["style"] in ("minimal", "chrome", "tanjun", "panel", ""),
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

    lua = shutil.which("lua")
    s.ok("lua on PATH", bool(lua), "lua missing")
    if lua:
        dump = r"""
local keys = {}
local shots = {}
local locked = {}
local function dummy()
    return setmetatable({}, {
        __call = function() return dummy() end,
        __index = function(_, k)
            if k == "exec_cmd" then
                return function(cmd)
                    shots[#shots + 1] = tostring(cmd)
                    return dummy()
                end
            end
            return dummy()
        end,
    })
end
hl = dummy()
function hl.bind(key, _, opts)
    keys[#keys + 1] = key
    if type(opts) == "table" and opts.locked then
        locked[#locked + 1] = key
    end
end
package.path = "./?.lua;" .. package.path
dofile("modules/binds.lua")
for _, k in ipairs(keys) do
    io.write("K ", k, "\n")
end
for _, c in ipairs(shots) do
    io.write("C ", c, "\n")
end
for _, k in ipairs(locked) do
    io.write("L ", k, "\n")
end
"""
        r = run(["lua", "-e", dump], cwd=str(COMP / "hyprland"))
        hypr_keys = []
        hypr_cmds = []
        hypr_locked = []
        for ln in (r.stdout or "").splitlines():
            if ln.startswith("K "):
                hypr_keys.append(ln[2:].strip())
            elif ln.startswith("C "):
                hypr_cmds.append(ln[2:].strip())
            elif ln.startswith("L "):
                hypr_locked.append(ln[2:].strip())
        s.eq("hypr binds dump exit", r.returncode, 0)
        s.ok("hypr binds listed", len(hypr_keys) >= 20, (r.stderr or "")[-300:] or str(hypr_keys[:8]))
        s.ok("hypr region shot Print", "Print" in hypr_keys, str(hypr_keys[-15:]))
        s.ok("hypr region shot Super+Shift+S", "SUPER + SHIFT + S" in hypr_keys, str(hypr_keys))
        s.ok(
            "hyprshot region in binds",
            any("hyprshot -m region" in c for c in hypr_cmds),
            str(hypr_cmds[-8:]),
        )
        s.ok("hypr Super+O logout", "SUPER + O" in hypr_keys, str(hypr_keys))
        s.ok(
            "hypr Super+O ends session",
            any("logout" in c for c in hypr_cmds),
            str(hypr_cmds[-8:]),
        )
        s.ok("hypr Super+O while locked", "SUPER + O" in hypr_locked, str(hypr_locked))

    niri_keys = []
    niri_shift_s = False
    niri_logout = False
    niri_logout_locked = False
    for line in (COMP / "niri" / "config" / "keybinds.kdl").read_text(encoding="utf-8").splitlines():
        t = line.strip()
        if not t or t.startswith("//") or t.startswith("binds") or t.startswith("}"):
            continue
        if "{" not in t:
            continue
        key = t.split("{", 1)[0].strip().split()[0]
        niri_keys.append(key)
        if key == "Mod+Shift+S" and "screenshot" in t:
            niri_shift_s = True
        if key == "Mod+O" and "logout" in t:
            niri_logout = True
            if "allow-when-locked=true" in t:
                niri_logout_locked = True
    s.ok("niri binds listed", "Mod+Tab" in niri_keys, str(niri_keys[:12]))
    s.ok("niri region shot Print", "Print" in niri_keys, str(niri_keys))
    s.ok("niri region shot Super+Shift+S", niri_shift_s, str(niri_keys))
    s.ok("niri Super+O logout", niri_logout, str(niri_keys))
    s.ok("niri Super+O while locked", niri_logout_locked, "Mod+O missing allow-when-locked")

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
