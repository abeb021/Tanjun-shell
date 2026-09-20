#!/usr/bin/env bash
set -euo pipefail
# Decode one cliphist row into ~/.cache/tanjun/clip/<id> and print the path.
# `--gc` trims the cache once; decode does not walk the directory.
dir="${XDG_CACHE_HOME:-$HOME/.cache}/tanjun/clip"
mkdir -p "$dir"

if [[ "${1:-}" == "--gc" ]]; then
  find "$dir" -type f -mtime +3 -delete 2>/dev/null || true
  while [[ "$(du -sk "$dir" 2>/dev/null | cut -f1)" -gt 32768 ]]; do
    oldest="$(find "$dir" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | head -1 | cut -d' ' -f2-)"
    [[ -n "$oldest" ]] || break
    rm -f "$oldest"
  done
  exit 0
fi

line="${1:-}"
[[ -n "$line" ]] || exit 1
id="${line%%$'\t'*}"
id="${id//[^0-9]/}"
[[ -n "$id" ]] || exit 1
out="$dir/$id"
if [[ ! -s "$out" ]]; then
  printf '%s\n' "$line" | cliphist decode >"$out"
fi
printf '%s\n' "$out"
