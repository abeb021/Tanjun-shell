from __future__ import annotations

from lib import SHELL, read


def score(query: str, text: str) -> int:
    if not query:
        return 0
    q = query.lower()
    t = text.lower()
    qi = 0
    streak = 0
    prev = -2
    total = 0
    for ti in range(len(t)):
        if qi >= len(q):
            break
        if t[ti] != q[qi]:
            continue
        bonus = 1
        if ti == prev + 1:
            streak += 1
            bonus += streak * 3
        else:
            streak = 0
        pc = t[ti - 1] if ti > 0 else " "
        if pc in " ·/-":
            bonus += 6
        if ti == 0:
            bonus += 8
        total += bonus
        prev = ti
        qi += 1
    return total if qi == len(q) else -1


def register(s) -> None:
    src = read(SHELL / "modules" / "settings" / "fuzzy.js")
    s.has("fuzzy score", src, "function score")
    s.has("fuzzy rank", src, "function rank")
    s.has("fuzzy pragma library", src, ".pragma library")
    s.eq("fuzzy empty query", score("", "hello"), 0)
    s.eq("fuzzy miss", score("z", "abc"), -1)
    s.ok("fuzzy prefix beats later", score("sc", "screen page") > score("sc", "misc"))
    s.ok("fuzzy start bonus", score("s", "screen") > score("s", "as"))
    s.ok("fuzzy consecutive", score("scr", "screen") > score("scr", "sxcxr"))
    s.ok("fuzzy word start", score("p", "font page") > 0)
    cases = [
        ("font", "fonts UI Japanese icons size"),
        ("gamma", "screen monitor display scale gamma output edp"),
        ("lock", "lock idle password fingerprint"),
        ("wall", "wallpaper color from wall presets"),
        ("clock", "clock zones moscow melbourne"),
    ]
    for q, hay in cases:
        s.ok(f"fuzzy hits {q}", score(q, hay) > 0)
    s.ok("fuzzy case", score("ABC", "abc") > 0)
    settings = read(SHELL / "modules" / "settings" / "Settings.qml")
    s.has("settings fuzzy import", settings, "fuzzy.js")
    s.has("settings Ctrl+K", settings, "Ctrl+K")
