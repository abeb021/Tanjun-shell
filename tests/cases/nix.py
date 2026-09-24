from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

from lib import ROOT, run


def register(s) -> None:
    files = [
        ROOT / "flake.nix",
        ROOT / "nix" / "hm-module.nix",
        ROOT / "nix" / "nixos-module.nix",
        ROOT / "nix" / "package.nix",
    ]
    for path in files:
        s.ok(f"nix file {path.name}", path.is_file(), str(path))

    if not shutil.which("nix-instantiate"):
        s.ok("nix-instantiate (skip parse)", True, "not installed")
        return

    for path in files:
        r = run(["nix-instantiate", "--parse", str(path)])
        s.ok(f"parse {path.relative_to(ROOT)}", r.returncode == 0, (r.stderr or r.stdout or "").strip()[:200])
