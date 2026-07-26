#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/detect.sh"
source "$ROOT_DIR/lib/docker.sh"
source "$ROOT_DIR/lib/proxy.sh"
source "$ROOT_DIR/lib/smtp.sh"

cd "$ROOT_DIR"
printf '\n=== Vaultwarden LAU Installer ===\n\n'

install_docker_if_needed
[[ -f .env ]] || cp .env.example .env

if [[ "$(get_env ADMIN_TOKEN)" == "CHANGE_ME" || -z "$(get_env ADMIN_TOKEN)" ]]; then
  set_env ADMIN_TOKEN "$(openssl rand -base64 48 | tr -d '\n')"
  ok "Biztonságos ADMIN_TOKEN generálva."
fi

domain="$(prompt_default 'Vaultwarden domain (protokoll nélkül)' 'vault.example.com')"
set_env DOMAIN "https://${domain}"

info "Reverse proxy felismerés:"
mapfile -t detected < <(detect_proxy)
printf '  - %s\n' "${detected[@]}"

echo
echo "Reverse proxy mód:"
echo "1) Meglévő Dockeres Nginx"
echo "2) Meglévő hostos Nginx"
echo "3) Meglévő HAProxy"
echo "4) Nginx automatikus telepítése"
echo "5) Proxy nélkül (csak tesztelés)"
read -r -p "Választás: " proxy_choice

port="$(prompt_default 'Vaultwarden helyi port' '8080')"
case "$proxy_choice" in
  1)
    mode="docker-nginx"
    network="$(prompt_default 'Docker proxy hálózat neve' 'licensehub_frontend')"
    docker network inspect "$network" >/dev/null 2>&1 || die "A Docker hálózat nem létezik: $network"
    write_override "$mode" "" "$port" "$network"
    set_env DOCKER_PROXY_NETWORK "$network"
    ;;
  2) mode="host-nginx"; write_override "$mode" "127.0.0.1" "$port" ;;
  3) mode="haproxy"; write_override "$mode" "127.0.0.1" "$port" ;;
  4) mode="install-nginx"; write_override "$mode" "127.0.0.1" "$port" ;;
  5) mode="none"; write_override "$mode" "0.0.0.0" "$port"; warn "A szolgáltatás közvetlenül elérhető lesz a hálózaton." ;;
  *) die "Érvénytelen választás." ;;
esac
set_env PROXY_MODE "$mode"
set_env HOST_PORT "$port"

smtp_wizard

mkdir -p data backups
chmod 700 data backups
compose pull
compose up -d

if [[ "$mode" == "install-nginx" ]]; then
  install_host_nginx "$domain" "$port"
  warn "A TLS tanúsítványt külön állítsd be Certbottal vagy a saját DNS-szolgáltatód módszerével."
elif [[ "$mode" == "host-nginx" ]]; then
  sed "s/__DOMAIN__/${domain}/g; s/__PORT__/${port}/g" nginx/host.conf.template > "nginx/${domain}.conf"
  info "Nginx minta elkészült: nginx/${domain}.conf"
elif [[ "$mode" == "haproxy" ]]; then
  sed "s/__DOMAIN__/${domain}/g; s/__PORT__/${port}/g" haproxy/vaultwarden.cfg.template > "haproxy/${domain}.cfg"
  info "HAProxy minta elkészült: haproxy/${domain}.cfg"
fi

compose ps
printf '\nTelepítés kész.\nURL: https://%s\nAdmin: https://%s/admin\n' "$domain" "$domain"
