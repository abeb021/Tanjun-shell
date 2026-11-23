from __future__ import annotations

import importlib.util
import json
import os
import re
import shutil
import stat
import subprocess
import sys
import time
import zlib
from pathlib import Path

from lib import PALETTE_KEYS, ROOT, SCRIPTS, SHELL


def _write_png(path: Path, rgb: tuple[int, int, int], size: int = 8) -> None:
    """A flat PNG, so the matugen check needs no image library."""
    import struct

    raw = (b"\x00" + bytes(rgb) * size) * size

    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw))
        + chunk(b"IEND", b"")
    )


def _load_paint():
    path = SHELL / "scripts" / "tanjun-paint.py"
    spec = importlib.util.spec_from_file_location("tanjun_paint", path)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _load_pam():
    path = SHELL / "scripts" / "tanjun-pam.py"
    spec = importlib.util.spec_from_file_location("tanjun_pam", path)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def register(s) -> None:
    paint = _load_paint()
    pam_mod = _load_pam()

    s.eq("slug kind", paint.slug("Dark", "dark"), "dark")
    s.eq("slug drops path", paint.slug("../etc/passwd", "monochrome"), "monochrome")
    s.eq("slug wall kept", paint.slug("wall", "monochrome"), "wall")
    s.eq("slug empty", paint.slug("", "dark"), "dark")

    tmp = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "tanjun-paint-test"
    tmp.mkdir(parents=True, exist_ok=True)
    real = tmp / "background-real"
    real.write_text("keep me\n", encoding="utf-8")
    target = tmp / "wall.png"
    target.write_text("img", encoding="utf-8")
    paint.link_background(target, bg=real)
    s.ok("real background kept", real.is_file() and not real.is_symlink(), str(real))
    s.eq("real background intact", real.read_text(encoding="utf-8"), "keep me\n")

    link = tmp / "background-link"
    if link.exists() or link.is_symlink():
        link.unlink()
    paint.link_background(target, bg=link)
    s.ok("symlink background created", link.is_symlink(), str(link))
    s.eq("symlink points at wall", Path(os.path.realpath(link)), target.resolve())

    dirs = paint.wall_dirs()
    s.ok("wall dirs list", isinstance(dirs, list) and len(dirs) >= 1, str(dirs))
    s.ok(
        "wall dirs own tanjun",
        any("tanjun" in str(p) and "walls" in str(p) for p in dirs),
        str(dirs),
    )

    mdir = ROOT / "matugen"
    for name in ("config.toml", "config-niri.toml"):
        cfg = mdir / name
        s.ok(f"matugen {name} exists", cfg.is_file(), str(cfg))
        if cfg.is_file():
            text = cfg.read_text(encoding="utf-8")
            s.ok(f"matugen {name} palette template", "[templates.palette]" in text, text[:120])
            s.ok(f"matugen {name} skips update check", "version_check = false" in text, text[:120])

    tpl = mdir / "templates" / "palette.json"
    s.ok("matugen palette template exists", tpl.is_file(), str(tpl))
    if tpl.is_file():
        text = tpl.read_text(encoding="utf-8")
        for key in PALETTE_KEYS:
            s.ok(f"matugen template {key}", f'"{key}":' in text, key)

    matugen = shutil.which("matugen")
    if matugen is not None and tpl.is_file():
        sample_img = tmp / "matugen-wall.png"
        _write_png(sample_img, (32, 64, 96))
        cfg = tmp / "matugen-test.toml"
        out = tmp / "matugen-palette.json"
        niri_kdl = tmp / "matugen-niri.kdl"
        niri_tpl = mdir / "templates" / "niri.kdl"
        cfg.write_text(
            "[config]\nversion_check = false\nsource_color_index = 0\n\n"
            "[templates.palette]\n"
            f'input_path = "{tpl}"\noutput_path = "{out}"\n\n'
            "[templates.niri]\n"
            f'input_path = "{niri_tpl}"\noutput_path = "{niri_kdl}"\n',
            encoding="utf-8",
        )
        mt = subprocess.run(
            [matugen, "image", str(sample_img), "-c", str(cfg), "-m", "dark", "-t", "scheme-content", "-q"],
            capture_output=True,
            text=True,
            check=False,
        )
        s.eq("matugen exit", mt.returncode, 0)
        try:
            data = json.loads(out.read_text(encoding="utf-8")) if out.is_file() else {}
        except json.JSONDecodeError:
            data = {}
        s.ok("matugen palette accent", str(data.get("accent", "")).startswith("#"), str(data)[:120])
        s.ok("matugen palette keys", all(k in data for k in PALETTE_KEYS), str(sorted(data)))
        kdl = niri_kdl.read_text(encoding="utf-8") if niri_kdl.is_file() else ""
        s.ok("matugen niri kdl", "active-color" in kdl and "{{" not in kdl, kdl[:120])

    # Host metrics are read in-process by shell/services/Host.qml now, so there is
    # no helper script to unit-test and no Python entry point to exercise. The live
    # numbers are checked with `qs ipc call tanjun hostJson`.
    host_src = (SHELL / "services" / "Host.qml").read_text(encoding="utf-8")
    s.ok("host has no helper script", not (SHELL / "scripts" / "tanjun-host.py").exists(), "script")
    s.ok("host reads proc stat", '"/proc/stat"' in host_src, host_src[:80])
    s.ok("host lists procs with ps", '"ps"' in host_src, "ps")
    s.ok("host reloads each source", "statFile.reload()" in host_src, "reload")

    buds = (ROOT / "scripts" / "bluetooth.sh").read_text(encoding="utf-8")
    s.ok("buds script has no MAC", not re.search(r"(?i)([0-9a-f]{2}:){5}[0-9a-f]{2}", buds), buds[:200])

    pam = (SHELL / "pam" / "password.conf").read_text(encoding="utf-8")
    s.ok("pam has faillock", "pam_faillock.so" in pam, pam)
    s.ok("pam unix sufficient", "auth sufficient pam_unix.so" in pam, pam)
    s.ok("pam unix not required", "auth required pam_unix.so" not in pam, pam)

    idle_hypr = (ROOT / "compositors" / "hyprland" / "hypridle.conf").read_text(encoding="utf-8")
    s.ok("hypridle unused", idle_hypr.lower().startswith("# unused") or "Idle.qml" in idle_hypr, idle_hypr[:180])
    idle_niri = (ROOT / "compositors" / "niri" / "scripts" / "idle.sh").read_text(encoding="utf-8")
    s.ok("niri idle unused", "Idle.qml" in idle_niri or idle_niri.lower().startswith("# unused"), idle_niri[:180])

    cache = tmp / "clip-cache"
    clip_dir = cache / "tanjun" / "clip"
    clip_dir.mkdir(parents=True, exist_ok=True)
    now = time.time()
    for i in range(5):
        blob = clip_dir / f"old{i}"
        blob.write_bytes(b"x" * (9 * 1024 * 1024))
        os.utime(blob, (now - 50 + i, now - 50 + i))
    keep = clip_dir / "1"
    keep.write_text("decoded\n", encoding="utf-8")
    env = os.environ.copy()
    env["XDG_CACHE_HOME"] = str(cache)
    gc = subprocess.run(
        ["bash", str(SHELL / "scripts" / "clip-decode.sh"), "--gc"],
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )
    s.eq("clip-gc exit", gc.returncode, 0)
    total_kb = sum(p.stat().st_size for p in clip_dir.iterdir() if p.is_file()) // 1024
    s.ok("clip-gc under 32MiB", total_kb <= 32768, str(total_kb))
    s.ok("clip-gc keeps file", keep.is_file(), str(keep))
    decoded = subprocess.run(
        ["bash", str(SHELL / "scripts" / "clip-decode.sh"), "1\tbinary"],
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )
    s.eq("clip-decode exit", decoded.returncode, 0)
    s.ok("clip-decode prints keep", "tanjun/clip/1" in (decoded.stdout or ""), decoded.stdout)
    s.ok("clip keep file remains", keep.is_file(), str(keep))

    example = json.loads((ROOT / "config.example.json").read_text(encoding="utf-8"))
    svc = example.get("services") if isinstance(example, dict) else None
    if isinstance(svc, dict) and "budsMac" in svc:
        s.ok("example budsMac empty", not svc.get("budsMac"), str(svc.get("budsMac")))

    # Inhibitor parsing lives in Idle.qml: the shell reads systemd-inhibit's own
    # table, so there is no helper script to unit-test here.
    idle_src = (SHELL / "services" / "Idle.qml").read_text(encoding="utf-8")
    s.ok("idle reads systemd-inhibit", '"systemd-inhibit", "--list"' in idle_src, "command")
    s.ok("idle has no helper script", not (SHELL / "scripts" / "tanjun-idle.py").exists(), "script")

    src_pam = SHELL / "pam"
    dest_pam = tmp / "pam-ok"
    got = pam_mod.install(src_pam, dest_pam)
    s.eq("pam install dest", got, dest_pam)
    pw = dest_pam / "password.conf"
    s.ok("pam dest exists", pw.is_file(), str(pw))
    s.eq("pam dest mode", stat.S_IMODE(pw.stat().st_mode), 0o600)
    s.ok("pam dest faillock", "pam_faillock.so" in pw.read_text(encoding="utf-8"), pw.read_text(encoding="utf-8")[:80])

    bad = tmp / "pam-bad"
    bad.mkdir(parents=True, exist_ok=True)
    dirty = bad / "password.conf"
    dirty.write_text("auth required pam_permit.so\n", encoding="utf-8")
    dirty.chmod(0o666)
    s.eq("pam refuse world writable", pam_mod.install(src_pam, bad), None)
    s.eq("pam world file left", dirty.read_text(encoding="utf-8"), "auth required pam_permit.so\n")
