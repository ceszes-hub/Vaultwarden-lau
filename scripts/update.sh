#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"
cd "$ROOT_DIR"
"$ROOT_DIR/scripts/backup.sh"
compose pull
compose up -d --remove-orphans
docker image prune -f
compose ps
