from __future__ import annotations

import json
import shutil
import subprocess

from lib import SHELL


def _js(expr: str) -> tuple[str, int]:
    src = (SHELL / "modules" / "settings" / "fuzzy.js").read_text(encoding="utf-8")
    src = src.replace(".pragma library", "")
    r = subprocess.run(
        ["node", "-e", src + f"\nprocess.stdout.write(JSON.stringify({expr}))"],
        check=False,
        capture_output=True,
        text=True,
    )
    return (r.stdout or "").strip(), r.returncode


def register(s) -> None:
    node = shutil.which("node")
    s.ok("node on PATH", bool(node), "node missing")
    s.exists(SHELL / "modules" / "settings" / "fuzzy.js")
    if not node:
        return

    out, code = _js('score("", "hello")')
    s.eq("fuzzy empty query", json.loads(out) if code == 0 else out, 0)
    out, code = _js('score("z", "abc")')
    s.eq("fuzzy miss", json.loads(out) if code == 0 else out, -1)
    sc, _ = _js('score("sc", "screen page")')
    misc, _ = _js('score("sc", "misc")')
    s.ok("fuzzy prefix beats later", json.loads(sc) > json.loads(misc))
    start, _ = _js('score("s", "screen")')
    later, _ = _js('score("s", "as")')
    s.ok("fuzzy start bonus", json.loads(start) > json.loads(later))
    cons, _ = _js('score("scr", "screen")')
    skip, _ = _js('score("scr", "sxcxr")')
    s.ok("fuzzy consecutive", json.loads(cons) > json.loads(skip))
    word, _ = _js('score("p", "font page")')
    s.ok("fuzzy word start", json.loads(word) > 0)
    for q, hay in (
        ("font", "fonts UI Japanese icons size"),
        ("gamma", "screen monitor display scale gamma output edp"),
        ("lock", "lock idle password fingerprint"),
        ("wall", "wallpaper color from wall presets"),
        ("clock", "clock zones moscow melbourne"),
    ):
        hit, code = _js(f"score({q!r}, {hay!r})")
        s.ok(f"fuzzy hits {q}", code == 0 and json.loads(hit) > 0, hit)
    case, _ = _js('score("ABC", "abc")')
    s.ok("fuzzy case", json.loads(case) > 0)
    ranked, code = _js('rank("scr", [{title:"screen", hay:"screen page"}, {title:"misc", hay:"misc"}])')
    s.eq("fuzzy rank exit", code, 0)
    rows = json.loads(ranked) if code == 0 else []
    s.ok("fuzzy rank hits", isinstance(rows, list) and len(rows) == 1, ranked)
    if rows:
        s.eq("fuzzy rank first", rows[0]["title"], "screen")
