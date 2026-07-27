#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"; source "$ROOT_DIR/lib/common.sh"
cd "$ROOT_DIR"; [[ -f .env ]] || die "Nincs .env; előbb telepítsd."
compose ps
status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$(get_env CONTAINER_NAME | sed 's/^$/vaultwarden/')" 2>/dev/null || true)"
case "$status" in healthy|running) ok "Konténer állapota: $status";; starting) warn "Konténer még indul.";; *) warn "Konténer állapota: ${status:-ismeretlen}"; compose logs --tail=40 vaultwarden; exit 1;; esac
url="$(get_env DOMAIN)"; if command_exists curl && [[ -n "$url" ]]; then code="$(curl -kLsS -o /dev/null -w '%{http_code}' --max-time 10 "$url/alive" || true)"; [[ "$code" =~ ^2|3 ]] && ok "HTTP ellenőrzés: $code" || warn "HTTP ellenőrzés: ${code:-hiba}"; fi
