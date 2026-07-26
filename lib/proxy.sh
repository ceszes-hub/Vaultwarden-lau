#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

write_override() {
  local mode="$1" bind="${2:-127.0.0.1}" port="${3:-8080}" network="${4:-licensehub_frontend}"
  case "$mode" in
    docker-nginx|docker-haproxy)
      cat > "$ROOT_DIR/compose.override.yaml" <<EOF2
services:
  vaultwarden:
    networks:
      - proxy
networks:
  proxy:
    external: true
    name: ${network}
EOF2
      ;;
    host-nginx|haproxy|install-nginx)
      cat > "$ROOT_DIR/compose.override.yaml" <<EOF2
services:
  vaultwarden:
    ports:
      - "${bind}:${port}:80"
EOF2
      ;;
    none)
      cat > "$ROOT_DIR/compose.override.yaml" <<EOF2
services:
  vaultwarden:
    ports:
      - "0.0.0.0:${port}:80"
EOF2
      ;;
    *) die "Ismeretlen proxy mód: $mode" ;;
  esac
}

install_host_nginx() {
  require_root
  local domain="$1" port="$2"
  apt-get update
  apt-get install -y nginx
  sed "s/__DOMAIN__/${domain}/g; s/__PORT__/${port}/g" \
    "$ROOT_DIR/nginx/host.conf.template" > "/etc/nginx/sites-available/${domain}.conf"
  ln -sfn "/etc/nginx/sites-available/${domain}.conf" "/etc/nginx/sites-enabled/${domain}.conf"
  nginx -t
  systemctl enable --now nginx
  systemctl reload nginx
  ok "Nginx telepítve és konfigurálva."
}
