#!/usr/bin/env bash
set -Eeuo pipefail
# shellcheck source=lib/common.sh
source "${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/common.sh"
initialize_env(){
  [[ -f "$ENV_FILE" ]] || cp "$ROOT_DIR/.env.example" "$ENV_FILE"
  chmod 600 "$ENV_FILE"
  local token="$(get_env ADMIN_TOKEN)"
  if [[ -z "$token" || "$token" == CHANGE_ME ]]; then
    command_exists openssl || die "Az openssl szükséges az ADMIN_TOKEN generálásához."
    set_env ADMIN_TOKEN "$(openssl rand -base64 48 | tr -d '\n')"
    ok "Biztonságos ADMIN_TOKEN generálva."
  fi
}
configure_core(){
  local current domain signup
  current="$(get_env DOMAIN)"; current="${current#https://}"; current="${current#http://}"; current="${current:-vault.example.com}"
  while true; do domain="$(trim "$(prompt_default 'Vaultwarden domain (protokoll nélkül)' "$current")")"; validate_domain "$domain" && break; warn "Érvénytelen domain."; done
  set_env DOMAIN "https://$domain"
  set_env TZ "$(prompt_default 'Időzóna' "${TZ:-Europe/Budapest}")"
  if confirm "Engedélyezed a nyilvános regisztrációt?" n; then signup=true; else signup=false; fi
  set_env SIGNUPS_ALLOWED "$signup"
  printf '%s' "$domain"
}
