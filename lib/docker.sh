#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

install_docker_if_needed() {
  if command_exists docker && docker compose version >/dev/null 2>&1; then
    ok "Docker és Docker Compose elérhető."
    return
  fi
  require_root
  info "Docker telepítése az Ubuntu/Debian csomagtárolóból..."
  apt-get update
  apt-get install -y docker.io docker-compose-v2 ca-certificates curl openssl
  systemctl enable --now docker
  ok "Docker telepítve."
}
