#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

info() { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[ OK ]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[HIBA]\033[0m %s\n' "$*" >&2; exit 1; }

require_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    die "Ezt a műveletet rootként vagy sudo-val futtasd."
  fi
}

command_exists() { command -v "$1" >/dev/null 2>&1; }

prompt_default() {
  local prompt="$1" default="$2" value
  read -r -p "$prompt [$default]: " value
  printf '%s' "${value:-$default}"
}

confirm() {
  local prompt="$1" default="${2:-n}" answer suffix
  [[ "$default" == "y" ]] && suffix="Y/n" || suffix="y/N"
  read -r -p "$prompt [$suffix]: " answer
  answer="${answer:-$default}"
  [[ "$answer" =~ ^[YyIi]$ ]]
}

set_env() {
  local key="$1" value="$2" file="${3:-$ROOT_DIR/.env}"
  touch "$file"
  if grep -qE "^${key}=" "$file"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$file"
  else
    printf '%s=%s\n' "$key" "$value" >> "$file"
  fi
}

get_env() {
  local key="$1" file="${2:-$ROOT_DIR/.env}"
  [[ -f "$file" ]] || return 0
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2-
}

compose() {
  docker compose -f "$ROOT_DIR/compose.yaml" -f "$ROOT_DIR/compose.override.yaml" --env-file "$ROOT_DIR/.env" "$@"
}
