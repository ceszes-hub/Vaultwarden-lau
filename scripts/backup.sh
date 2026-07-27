#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"; source "$ROOT_DIR/lib/common.sh"
cd "$ROOT_DIR"; [[ -d data ]] || die "A data könyvtár nem található."; mkdir -p backups; chmod 700 backups
stamp="$(date +%Y%m%d-%H%M%S)"; out="backups/vaultwarden-${stamp}.tar.gz"
compose exec -T vaultwarden sh -c 'sqlite3 /data/db.sqlite3 ".backup /data/db-backup.sqlite3"' >/dev/null 2>&1 || warn "SQLite online backup nem futott; fájlrendszer-pillanatkép készül."
tar --exclude='data/icon_cache' -czf "$out" data .env compose.override.yaml 2>/dev/null || tar -czf "$out" data .env compose.override.yaml
rm -f data/db-backup.sqlite3
sha256sum "$out" > "$out.sha256"; chmod 600 "$out" "$out.sha256"; ok "Backup: $out"
