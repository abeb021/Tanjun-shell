from __future__ import annotations

from lib import SHELL, balanced, qml_files, read


def register(s) -> None:
    files = qml_files()
    s.ok("qml files exist", len(files) > 40, f"count {len(files)}")
    for p in files:
        text = read(p)
        rel = p.relative_to(SHELL)
        s.ok(f"qml braces {rel}", balanced(text))
        s.ok(f"qml nonempty {rel}", len(text.strip()) > 0)
        s.ok(
            f"qml import {rel}",
            "import " in text or text.lstrip().startswith("pragma") or "//@ pragma" in text[:80],
        )
    qmldir = read(SHELL / "services" / "qmldir")
    s.has("qmldir module", qmldir, "module services")
    for name in (
        "Config",
        "Compositor",
        "ShellState",
        "Theme",
        "Time",
        "Layout",
        "Audio",
        "Battery",
        "Backlight",
        "Net",
        "Media",
        "Host",
        "Weather",
        "Notifs",
        "Motion",
        "Launches",
        "Screens",
        "Idle",
        "Lock",
    ):
        s.has(f"qmldir {name}", qmldir, f"singleton {name}")
        s.exists(SHELL / "services" / f"{name}.qml")
    s.lacks("qmldir no HyprHost singleton", qmldir, "HyprHost")
    s.lacks("qmldir no NiriHost singleton", qmldir, "NiriHost")
