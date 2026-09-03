#!/usr/bin/env bash
set -euo pipefail
expr="${1:-}"
[[ -n "$expr" ]] || exit 1
if command -v qalc >/dev/null 2>&1; then
  qalc -t -- "$expr"
  exit 0
fi
python3 - "$expr" <<'PY'
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
PY
