#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"
[[ $# -eq 1 ]] || die "Használat: $0 backups/vaultwarden-DATUM.tar.gz"
archive="$1"
[[ -f "$archive" ]] || die "Nincs ilyen mentés: $archive"
cd "$ROOT_DIR"
confirm "A visszaállítás leállítja a Vaultwardent. Folytatod?" n || exit 0
compose down
tar -xzf "$archive"
compose up -d
ok "Visszaállítás kész."
