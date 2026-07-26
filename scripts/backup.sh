#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"
cd "$ROOT_DIR"
mkdir -p backups
stamp="$(date +%Y%m%d-%H%M%S)"
compose exec -T vaultwarden /vaultwarden backup >/dev/null 2>&1 || warn "A beépített SQLite backup nem futott; fájlszintű mentés készül."
tar --exclude='./backups' --exclude='./.git' -czf "backups/vaultwarden-${stamp}.tar.gz" data .env compose.yaml compose.override.yaml
find backups -type f -name 'vaultwarden-*.tar.gz' -mtime +30 -delete
ok "Mentés: backups/vaultwarden-${stamp}.tar.gz"
