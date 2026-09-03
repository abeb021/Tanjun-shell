#!/usr/bin/env bash
# Back-compat: same as scripts/setup.sh
exec "$(cd "$(dirname "$0")" && pwd)/setup.sh" "$@"
