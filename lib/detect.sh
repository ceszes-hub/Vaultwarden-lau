#!/usr/bin/env bash
set -Eeuo pipefail
# shellcheck source=lib/common.sh
source "${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/common.sh"
OS_ID='unknown'; OS_VERSION='unknown'; ARCH="$(uname -m)"
detect_os(){ if [[ -r /etc/os-release ]]; then . /etc/os-release; OS_ID="${ID:-unknown}"; OS_VERSION="${VERSION_ID:-unknown}"; fi; }
port_owner(){ local p="$1"; if command_exists ss; then ss -ltnp 2>/dev/null | awk -v pat=":${p} " '$0 ~ pat {print; exit}'; fi; }
docker_proxy_containers(){ command_exists docker || return 0; docker ps --format '{{.Names}} {{.Image}}' 2>/dev/null | grep -Ei 'nginx|haproxy|traefik|caddy' || true; }
detect_proxy(){ local found=0; if systemctl is-active --quiet nginx 2>/dev/null; then echo 'host-nginx'; found=1; fi; if systemctl is-active --quiet haproxy 2>/dev/null; then echo 'host-haproxy'; found=1; fi; while read -r line; do [[ -z "$line" ]] && continue; case "$line" in *[Nn]ginx*) echo 'docker-nginx';; *[Hh][Aa][Pp]roxy*) echo 'docker-haproxy';; *[Tt]raefik*) echo 'docker-traefik';; *[Cc]addy*) echo 'docker-caddy';; esac; found=1; done < <(docker_proxy_containers); (( found )) || echo 'none'; }
check_dns(){ local domain="$1"; getent ahostsv4 "$domain" 2>/dev/null | awk 'NR==1{print $1}'; }
public_ip(){ curl -4fsS --max-time 8 https://api.ipify.org 2>/dev/null || true; }
preflight_report(){ detect_os; printf '\nKörnyezet:\n'; printf '  OS: %s %s\n  Architektúra: %s\n' "$OS_ID" "$OS_VERSION" "$ARCH"; printf '  Docker: %s\n' "$(command_exists docker && echo igen || echo nem)"; printf '  Compose: %s\n' "$(docker compose version >/dev/null 2>&1 && echo igen || echo nem)"; printf '  80/tcp: %s\n' "$(port_owner 80 || echo szabad)"; printf '  443/tcp: %s\n' "$(port_owner 443 || echo szabad)"; printf '  Felismert proxy: %s\n\n' "$(detect_proxy | paste -sd, -)"; }
