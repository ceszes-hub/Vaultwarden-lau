#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"; source "$ROOT_DIR/lib/common.sh"
cd "$ROOT_DIR"; confirm "Leállítod és eltávolítod a Vaultwarden konténert? Az adatok megmaradnak." n || exit 0; compose down; ok "Konténer eltávolítva. A data és backups könyvtár megmaradt."
