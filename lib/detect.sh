#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

detect_proxy() {
  local found=()
  if systemctl is-active --quiet nginx 2>/dev/null; then found+=("host-nginx"); fi
  if systemctl is-active --quiet haproxy 2>/dev/null; then found+=("haproxy"); fi
  if command_exists docker; then
    if docker ps --format '{{.Names}} {{.Image}}' 2>/dev/null | grep -Eqi 'nginx|nginx-proxy|swag'; then
      found+=("docker-nginx")
    fi
    if docker ps --format '{{.Names}} {{.Image}}' 2>/dev/null | grep -Eqi 'haproxy'; then
      found+=("docker-haproxy")
    fi
  fi
  printf '%s\n' "${found[@]:-none}"
}

check_port() {
  local port="$1"
  if command_exists ss && ss -ltn "sport = :$port" | tail -n +2 | grep -q .; then
    return 1
  fi
  return 0
}
