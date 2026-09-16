from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SHELL = ROOT / "shell"
COMP = ROOT / "compositors"
SCRIPTS = ROOT / "scripts"

FORBIDDEN = ("Omarchy", "Ryoku", "Serpantinum")
CYRILLIC = range(0x0400, 0x04FF)

PALETTE_KEYS = (
    "name",
    "label",
    "kind",
    "accent",
    "accentHover",
    "critical",
    "warning",
    "info",
    "good",
    "fg",
    "fgSub",
    "bg",
    "surface",
    "surfaceHover",
)

HOST_FUNCS = (
    "activateWorkspace",
    "moveToWorkspace",
    "cycleWorkspace",
    "exitSession",
    "toggleOverview",
    "focusWindow",
    "cycleLayout",
    "parseMonitors",
    "applyMonitor",
    "persistMonitors",
    "setGamma",
    "identityGamma",
    "readGamma",
)

HOST_PROPS = (
    "live",
    "hasGamma",
    "grabFocus",
    "screenNote",
    "monitorQuery",
    "gammaQuery",
    "focusedOutput",
    "focusedWorkspaceId",
    "occupied",
    "layoutName",
)

IPC = (
    "toggleLauncher",
    "toggleSidebar",
    "toggleAudio",
    "toggleNetwork",
    "toggleCalendar",
    "toggleBattery",
    "toggleNotify",
    "toggleClipboard",
    "toggleSettings",
    "toggleOverview",
    "toggleDnd",
    "closeMenus",
    "lock",
)

FACE_DIRS = (SHELL / "modules",)


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def qml_files() -> list[Path]:
    return sorted(SHELL.rglob("*.qml"))


def tracked_text_files() -> list[Path]:
    text_suf = {
        ".qml",
        ".js",
        ".json",
        ".md",
        ".sh",
        ".py",
        ".kdl",
        ".lua",
        ".conf",
        ".txt",
        ".mdc",
        ".svg",
        ".css",
        ".html",
        ".yml",
        ".yaml",
    }
    out = []
    for base in (SHELL, COMP, SCRIPTS, ROOT / "tests"):
        if not base.exists():
            continue
        for p in base.rglob("*"):
            if not p.is_file():
                continue
            if p.suffix.lower() not in text_suf:
                continue
            out.append(p)
    for name in ("README.md", "TODO.md"):
        p = ROOT / name
        if p.is_file():
            out.append(p)
    return out


def balanced(text: str) -> bool:
    n = 0
    for c in text:
        if c == "{":
            n += 1
        elif c == "}":
            n -= 1
            if n < 0:
                return False
    return n == 0


def has_cyrillic(text: str) -> bool:
    return any(ord(c) in CYRILLIC for c in text)
