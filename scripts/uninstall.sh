#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"
cd "$ROOT_DIR"
confirm "Biztosan leállítod és eltávolítod a Vaultwarden konténert? Az adatok megmaradnak." n || exit 0
compose down
ok "Konténer eltávolítva; a data/ könyvtár megmaradt."
