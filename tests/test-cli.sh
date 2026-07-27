#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output="$($ROOT_DIR/lau help)"
grep -q 'doctor' <<<"$output"
grep -q 'backup' <<<"$output"
if "$ROOT_DIR/lau" does-not-exist >/dev/null 2>&1; then
  echo 'Ismeretlen parancs hibásan sikeres.' >&2
  exit 1
fi
echo 'CLI smoke test: OK'
