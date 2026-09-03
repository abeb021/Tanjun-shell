#!/usr/bin/env bash
set -euo pipefail
# Decode one cliphist row into ~/.cache/tanjun/clip/<id> and print the path.
line="${1:-}"
[[ -n "$line" ]] || exit 1
id="${line%%$'\t'*}"
id="${id//[^0-9]/}"
[[ -n "$id" ]] || exit 1
dir="${XDG_CACHE_HOME:-$HOME/.cache}/tanjun/clip"
mkdir -p "$dir"
out="$dir/$id"
if [[ ! -s "$out" ]]; then
  printf '%s\n' "$line" | cliphist decode >"$out"
fi
printf '%s\n' "$out"
