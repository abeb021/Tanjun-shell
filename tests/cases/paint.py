from __future__ import annotations

import importlib.util
import json
import os
import re
import stat
import subprocess
import sys
import time
from pathlib import Path

from lib import ROOT, SCRIPTS, SHELL


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


def _load_idle():
    path = SHELL / "scripts" / "tanjun-idle.py"
    spec = importlib.util.spec_from_file_location("tanjun_idle", path)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _load_host():
    path = SHELL / "scripts" / "tanjun-host.py"
    spec = importlib.util.spec_from_file_location("tanjun_host", path)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def register(s) -> None:
    paint = _load_paint()
    host = _load_host()
    pam_mod = _load_pam()
    idle_mod = _load_idle()

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

    try:
        from PIL import Image
    except ImportError:
        Image = None
    if Image is not None:
        sample_img = tmp / "sample-wall.png"
        Image.new("RGB", (24, 24), (32, 64, 96)).save(sample_img)
        pal1 = paint.sample_palette(sample_img)
        s.ok("sample pal dict", isinstance(pal1, dict) and pal1.get("kind") == "wall", str(pal1)[:120])
        s.ok("sample pal accent", isinstance(pal1.get("accent"), str) and pal1["accent"].startswith("#"), str(pal1.get("accent")))

    rows = host.procs(limit=3)
    s.ok("procs list", isinstance(rows, list), str(type(rows)))
    if rows:
        s.ok("proc has pid", isinstance(rows[0].get("pid"), int), str(rows[0]))
        s.ok("proc has name", isinstance(rows[0].get("name"), str) and rows[0]["name"], str(rows[0]))

    first, prev = host.sample(None, True)
    s.ok("sample dict", isinstance(first, dict) and "cpu" in first, str(type(first)))
    s.ok("sample procs list", isinstance(first.get("procs"), list), str(first.get("procs")))
    s.ok("sample facts", bool(first.get("distro") or first.get("kernel")), str(first.keys()))
    second, _ = host.sample(prev, False)
    s.ok("sample tick dict", isinstance(second, dict) and "cpu" in second, str(second))
    s.ok("sample tick no facts", "distro" not in second, str(second.keys()))

    watch_env = os.environ.copy()
    watch_env["TANJUN_HOST_INTERVAL"] = "0.05"
    watch = subprocess.Popen(
        [sys.executable, str(SHELL / "scripts" / "tanjun-host.py"), "--watch"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        env=watch_env,
    )
    try:
        line1 = watch.stdout.readline() if watch.stdout else ""
        line2 = watch.stdout.readline() if watch.stdout else ""
    finally:
        watch.terminate()
        try:
            watch.wait(timeout=2)
        except subprocess.TimeoutExpired:
            watch.kill()
            watch.wait(timeout=1)
    try:
        w1 = json.loads(line1.strip() or "null")
        w1_err = ""
    except json.JSONDecodeError as e:
        w1 = None
        w1_err = str(e)
    try:
        w2 = json.loads(line2.strip() or "null")
        w2_err = ""
    except json.JSONDecodeError as e:
        w2 = None
        w2_err = str(e)
    s.ok("watch line 1 json", isinstance(w1, dict) and not w1_err, w1_err or line1[:120])
    s.ok("watch line 2 json", isinstance(w2, dict) and not w2_err, w2_err or line2[:120])
    s.ok("watch line 1 cpu", isinstance(w1, dict) and "cpu" in w1, str(w1))
    s.ok("watch line 2 cpu", isinstance(w2, dict) and "cpu" in w2, str(w2))

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

    s.ok(
        "idle block sleep",
        idle_mod.blocked("firefox\t1000\tabeb\t1\tfirefox\tsleep:idle\tvideo\tblock\n"),
        "sleep+idle block",
    )
    s.ok(
        "idle delay not block",
        not idle_mod.blocked("firefox\t1000\tabeb\t1\tfirefox\tsleep\tvideo\tdelay\n"),
        "delay",
    )
    s.ok("idle empty not block", not idle_mod.blocked(""), "empty")

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
