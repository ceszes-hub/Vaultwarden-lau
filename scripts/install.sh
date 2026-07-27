#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=lib/common.sh
source "$ROOT_DIR/lib/common.sh"
# shellcheck source=lib/detect.sh
source "$ROOT_DIR/lib/detect.sh"
# shellcheck source=lib/docker.sh
source "$ROOT_DIR/lib/docker.sh"
# shellcheck source=lib/config.sh
source "$ROOT_DIR/lib/config.sh"
# shellcheck source=lib/proxy.sh
source "$ROOT_DIR/lib/proxy.sh"
# shellcheck source=lib/smtp.sh
source "$ROOT_DIR/lib/smtp.sh"
# shellcheck source=lib/ssl.sh
source "$ROOT_DIR/lib/ssl.sh"
cd "$ROOT_DIR"
if [[ -f .env && -f compose.override.yaml ]] && ! confirm "Már létezik konfiguráció. Újrafuttatod a telepítési varázslót?" n; then exec "$ROOT_DIR/lau"; fi
printf '\n=== Vaultwarden LAU telepítő ===\n'
preflight_report
install_docker_if_needed
initialize_env
domain="$(configure_core)"
configure_proxy "$domain"
smtp_wizard
mkdir -p data backups; chmod 700 data backups
compose config >/dev/null
compose pull
compose up -d
ssl_wizard "$domain"
"$ROOT_DIR/scripts/health.sh" || true
printf '\nTelepítés kész.\nURL: https://%s\nAdmin: https://%s/admin\n' "$domain" "$domain"
