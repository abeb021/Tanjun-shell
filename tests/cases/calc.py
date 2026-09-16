from __future__ import annotations

import os
import subprocess

from lib import SHELL

PY = r"""
import ast
import sys

src = sys.argv[1]
tree = ast.parse(src, mode="eval")
ok = (
    ast.Expression,
    ast.BinOp,
    ast.UnaryOp,
    ast.Constant,
    ast.Add,
    ast.Sub,
    ast.Mult,
    ast.Div,
    ast.FloorDiv,
    ast.Mod,
    ast.Pow,
    ast.UAdd,
    ast.USub,
    ast.Load,
)
for node in ast.walk(tree):
    if not isinstance(node, ok):
        sys.exit(1)
print(eval(compile(tree, "<calc>", "eval"), {"__builtins__": {}}, {}))
"""


def register(s) -> None:
    calc = SHELL / "scripts" / "tanjun-calc.sh"
    s.exists(calc)

    def run_sh(expr: str) -> tuple[str, int]:
        r = subprocess.run(
            ["bash", str(calc), expr],
            check=False,
            capture_output=True,
            text=True,
        )
        out = (r.stdout or "").strip().replace("−", "-").replace("–", "-")
        return out, r.returncode

    def run_py(expr: str) -> tuple[str, int]:
        r = subprocess.run(
            ["python3", "-c", PY, expr],
            check=False,
            capture_output=True,
            text=True,
        )
        return (r.stdout or "").strip(), r.returncode

    out, code = run_sh("2+2")
    s.eq("calc 2+2", out.split("\n")[-1] if out else out, "4")
    s.eq("calc 2+2 exit", code, 0)
    out, code = run_py("10/4")
    s.eq("calc 10/4", out, "2.5")
    s.eq("calc 10/4 exit", code, 0)
    out, code = run_py("2**8")
    s.eq("calc 2**8", out, "256")
    out, code = run_py("(1+2)*3")
    s.eq("calc group", out, "9")
    out, code = run_py("-7+3")
    s.eq("calc unary", out, "-4")
    _, code = run_sh("")
    s.ok("calc empty fails", code != 0)
    _, code = run_py("__import__('os')")
    s.ok("calc rejects import", code != 0)
    _, code = run_py("open('/etc/passwd')")
    s.ok("calc rejects open", code != 0)
    _, code = run_py("a")
    s.ok("calc rejects name", code != 0)
