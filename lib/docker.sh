#!/usr/bin/env bash
set -Eeuo pipefail
# shellcheck source=lib/common.sh
source "${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/common.sh"
install_docker_if_needed(){
  if command_exists docker && docker compose version >/dev/null 2>&1; then ok "Docker és Docker Compose elérhető."; return; fi
  require_root
  command_exists curl || { apt-get update; apt-get install -y curl ca-certificates; }
  if [[ -r /etc/os-release ]]; then . /etc/os-release; else die "Nem felismerhető Linux rendszer."; fi
  case "${ID:-}" in ubuntu|debian)
    info "Docker Engine telepítése a Docker hivatalos telepítőjével."
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker
    ;;
    *) die "Automatikus Docker-telepítés csak Debian/Ubuntu rendszeren támogatott. Telepítsd kézzel, majd futtasd újra.";;
  esac
  docker compose version >/dev/null 2>&1 || die "A Docker Compose plugin nem érhető el."
}
