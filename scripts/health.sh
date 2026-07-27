#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=lib/common.sh
source "$ROOT_DIR/lib/common.sh"

cd "$ROOT_DIR"
[[ -f .env ]] || die "Nincs .env; előbb telepítsd."

compose ps

container_name="$(get_env CONTAINER_NAME)"
container_name="${container_name:-vaultwarden}"
status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container_name" 2>/dev/null || true)"

case "$status" in
  healthy|running)
    ok "Konténer állapota: $status"
    ;;
  starting)
    warn "Konténer még indul."
    ;;
  *)
    warn "Konténer állapota: ${status:-ismeretlen}"
    compose logs --tail=40 vaultwarden
    exit 1
    ;;
esac

url="$(get_env DOMAIN)"
if command_exists curl && [[ -n "$url" ]]; then
  code="$(curl -kLsS -o /dev/null -w '%{http_code}' --max-time 10 "$url/alive" || true)"
  if [[ "$code" =~ ^(2|3)[0-9][0-9]$ ]]; then
    ok "HTTP ellenőrzés: $code"
  else
    warn "HTTP ellenőrzés: ${code:-hiba}"
  fi
fi
