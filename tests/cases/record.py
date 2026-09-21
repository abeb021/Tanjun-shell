from __future__ import annotations

from lib import ROOT, SCRIPTS, run


def register(s) -> None:
    script = SCRIPTS / "record.sh"
    s.exists(script)
    syn = run(["bash", "-n", str(script)])
    s.eq("record.sh syntax", syn.returncode, 0)
    dry = run(["bash", str(script), "--dry"])
    s.eq("record.sh dry", dry.returncode, 0)
    out = (dry.stdout or "") + (dry.stderr or "")
    s.ok("record dry desk 3", "desk 3" in out, out[:400])
    s.ok("record dry unlock check", "unlock check" in out, out[:400])
    for verb in (
        "toggleLauncher",
        "toggleClipboard",
        "toggleOverview",
        "toggleSidebar",
        "toggleSettings",
        "toggleAudio",
        "toggleNetwork",
        "toggleCalendar",
        "toggleBattery",
        "toggleNotify",
        "openSettingsPage",
        "closeMenus",
    ):
        s.ok(f"record dry {verb}", verb in out, out[:400])
    s.ok("record dry no lock", "ipc lock" not in out and " call tanjun lock" not in out, out)
    s.ok("record dry no logout", "logout" not in out, out)
    s.ok("record dry obs start", "obs start" in out, out[:400])
    s.ok("record dry obs stop", "obs stop" in out, out[-200:])
    s.ok("record dry videos dir", "record dir" in out and "Videos" in out, out[:500])
    s.ok("record dry theme save", "theme save" in out, out[:400])
    s.ok("record dry openWalls", "openWalls" in out, out)
    s.ok("record dry pictures", "Pictures" in out, out)
    s.ok("record dry wallpapers dir", "Wallpapers" in out or "wallpapers" in out, out)
    s.ok("record dry arch logo", "logo" in out and "pickWall" in out, out)
    s.ok("record dry pull colors", "setSampleWall true" in out, out)
    s.ok("record dry no emerald", "setTheme dark emerald" not in out, out[:800])
    s.ok("record dry rice folder", "hypr/assets/wallpapers" in out, out)
    s.ok("record dry rice cycle", "setWallpaper" in out and out.count("setWallpaper") >= 2, out[-800:])
    s.ok("record dry theme restore", "theme restore" in out, out[-400:])
    s.ok("record dry not wf-recorder", "wf-recorder" not in out, out[:200])
    rec_py = SCRIPTS / "obs-rec.py"
    s.exists(rec_py)
    try:
        import py_compile

        py_compile.compile(str(rec_py), doraise=True)
        err = ""
    except py_compile.PyCompileError as e:
        err = str(e)
    s.ok("py_compile obs-rec.py", not err, err)
    bad = run(["python3", str(rec_py)])
    s.eq("obs-rec usage exit", bad.returncode, 1)
    s.exists(ROOT / "scripts" / "shots.sh")
