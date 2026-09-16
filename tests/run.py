#!/usr/bin/env python3
"""Tanjun checks. Score = passed / total. Exit 1 if any fail."""
from __future__ import annotations

import importlib.util
import sys
import time
import traceback
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
CASES = HERE / "cases"
sys.path.insert(0, str(HERE))


class Suite:
    def __init__(self) -> None:
        self.passed = 0
        self.failed: list[str] = []

    def ok(self, name: str, cond: bool, msg: str = "") -> None:
        if cond:
            self.passed += 1
            return
        self.failed.append(f"{name}" + (f"  {msg}" if msg else ""))

    def eq(self, name: str, got, want) -> None:
        self.ok(name, got == want, f"got {got!r} want {want!r}")

    def has(self, name: str, text: str, needle: str) -> None:
        self.ok(name, needle in text, f"missing {needle!r}")

    def lacks(self, name: str, text: str, needle: str) -> None:
        self.ok(name, needle not in text, f"found {needle!r}")

    def file_has(self, path: Path, needle: str) -> None:
        self.has(f"{path.relative_to(ROOT)} has {needle!r}", path.read_text(encoding="utf-8"), needle)

    def exists(self, path: Path) -> None:
        self.ok(f"exists {path.relative_to(ROOT)}", path.is_file())


def load_cases() -> list:
    mods = []
    for path in sorted(CASES.glob("*.py")):
        if path.name.startswith("_"):
            continue
        spec = importlib.util.spec_from_file_location(f"cases.{path.stem}", path)
        if spec is None or spec.loader is None:
            continue
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        if hasattr(mod, "register"):
            mods.append(mod)
    return mods


def main() -> int:
    suite = Suite()
    t0 = time.time()
    for mod in load_cases():
        try:
            mod.register(suite)
        except Exception:
            suite.ok(f"{mod.__name__} register", False, traceback.format_exc())
    total = suite.passed + len(suite.failed)
    ms = int((time.time() - t0) * 1000)
    score = 0 if total == 0 else round(100 * suite.passed / total)
    for line in suite.failed:
        print(f"FAIL  {line}")
    print(f"{suite.passed} passed  {len(suite.failed)} failed  {total} checks  score {score}  {ms}ms")
    return 1 if suite.failed else 0


if __name__ == "__main__":
    sys.exit(main())
