#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"
cd "$ROOT_DIR"
compose ps
container="$(get_env CONTAINER_NAME)"; container="${container:-vaultwarden}"
health="$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}n/a{{end}}' "$container" 2>/dev/null || true)"
echo "Container health: ${health:-nem található}"
domain="$(get_env DOMAIN)"
if command_exists curl && [[ -n "$domain" ]]; then
  code="$(curl -kLsS -o /dev/null -w '%{http_code}' --max-time 15 "$domain/alive" || true)"
  echo "HTTP /alive: ${code:-hiba}"
fi
