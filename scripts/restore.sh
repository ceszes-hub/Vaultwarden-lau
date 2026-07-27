#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"; source "$ROOT_DIR/lib/common.sh"
archive="${1:-}"; [[ -n "$archive" ]] || archive="$(find "$ROOT_DIR/backups" -maxdepth 1 -name 'vaultwarden-*.tar.gz' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2-)"; [[ -f "$archive" ]] || die "Backup nem található. Add meg argumentumként."
confirm "A jelenlegi adatok felülíródnak. Folytatod?" n || exit 0
cd "$ROOT_DIR"; compose down; [[ -d data ]] && mv data "data.before-restore.$(date +%Y%m%d%H%M%S)"; tar -xzf "$archive"; chmod 600 .env 2>/dev/null || true; compose up -d; ok "Visszaállítás kész: $archive"
