#!/usr/bin/env bash
set -Eeuo pipefail
# shellcheck source=lib/common.sh
source "${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/common.sh"
write_override(){ local mode="$1" bind="$2" port="$3" network="${4:-}"; cat > "$OVERRIDE_FILE" <<YAML
services:
  vaultwarden:
YAML
  if [[ "$mode" == docker-* ]]; then cat >> "$OVERRIDE_FILE" <<YAML
    networks:
      - default
      - proxy
networks:
  proxy:
    external: true
    name: ${network}
YAML
  else cat >> "$OVERRIDE_FILE" <<YAML
    ports:
      - "${bind}:${port}:80"
YAML
  fi
}
install_host_nginx(){ local domain="$1" port="$2" target="/etc/nginx/sites-available/vaultwarden-lau.conf"; require_root; apt-get update; apt-get install -y nginx; sed "s/__DOMAIN__/${domain}/g; s/__PORT__/${port}/g" "$ROOT_DIR/nginx/host.conf.template" > "$target"; ln -sfn "$target" /etc/nginx/sites-enabled/vaultwarden-lau.conf; nginx -t; systemctl enable --now nginx; systemctl reload nginx; ok "Nginx konfigurálva."; }
configure_proxy(){
  local domain="$1" detected choice port mode network bind
  detected="$(detect_proxy | paste -sd, -)"; info "Felismert proxy: $detected"
  cat <<'MENU'
1) Meglévő Dockeres Nginx
2) Meglévő hostos Nginx
3) Meglévő HAProxy
4) Nginx automatikus telepítése
5) Proxy nélkül (tesztelés)
MENU
  read -r -p "Választás [2]: " choice; choice="${choice:-2}"
  while true; do port="$(prompt_default 'Vaultwarden helyi port' '8080')"; validate_port "$port" && break; warn "Érvénytelen port."; done
  case "$choice" in
    1) mode=docker-nginx; network="$(prompt_default 'Docker proxy hálózat neve' 'licensehub_frontend')"; docker network inspect "$network" >/dev/null 2>&1 || die "A Docker hálózat nem létezik: $network"; write_override "$mode" '' "$port" "$network"; set_env DOCKER_PROXY_NETWORK "$network";;
    2) mode=host-nginx; bind=127.0.0.1; write_override "$mode" "$bind" "$port"; sed "s/__DOMAIN__/${domain}/g; s/__PORT__/${port}/g" "$ROOT_DIR/nginx/host.conf.template" > "$ROOT_DIR/nginx/${domain}.conf"; info "Nginx minta: nginx/${domain}.conf";;
    3) mode=haproxy; bind=127.0.0.1; write_override "$mode" "$bind" "$port"; sed "s/__DOMAIN__/${domain}/g; s/__PORT__/${port}/g" "$ROOT_DIR/haproxy/vaultwarden.cfg.template" > "$ROOT_DIR/haproxy/${domain}.cfg"; info "HAProxy minta: haproxy/${domain}.cfg";;
    4) mode=install-nginx; bind=127.0.0.1; write_override "$mode" "$bind" "$port"; install_host_nginx "$domain" "$port";;
    5) mode=none; bind=0.0.0.0; write_override "$mode" "$bind" "$port"; warn "A szolgáltatás közvetlenül elérhető lesz a hálózaton.";;
    *) die "Érvénytelen választás.";;
  esac
  set_env PROXY_MODE "$mode"; set_env HOST_PORT "$port"
}
