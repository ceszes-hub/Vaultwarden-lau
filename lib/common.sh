#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env}"
OVERRIDE_FILE="${OVERRIDE_FILE:-$ROOT_DIR/compose.override.yaml}"

if [[ -t 1 ]]; then C_BLUE='\033[1;34m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_RED='\033[1;31m'; C_RESET='\033[0m'; else C_BLUE=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_RESET=''; fi
info(){ printf '%b[INFO]%b %s\n' "$C_BLUE" "$C_RESET" "$*"; }
ok(){ printf '%b[ OK ]%b %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn(){ printf '%b[WARN]%b %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
die(){ printf '%b[HIBA]%b %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }
command_exists(){ command -v "$1" >/dev/null 2>&1; }
require_root(){ [[ ${EUID:-$(id -u)} -eq 0 ]] || die "Futtasd sudo-val vagy rootként."; }
trim(){ local v="$*"; v="${v#"${v%%[![:space:]]*}"}"; v="${v%"${v##*[![:space:]]}"}"; printf '%s' "$v"; }
prompt_default(){ local prompt="$1" default="$2" value; read -r -p "$prompt [$default]: " value; printf '%s' "${value:-$default}"; }
prompt_secret(){ local prompt="$1" value; read -r -s -p "$prompt: " value; printf '\n' >&2; printf '%s' "$value"; }
confirm(){ local prompt="$1" default="${2:-n}" answer suffix; [[ "$default" == y ]] && suffix='Y/n' || suffix='y/N'; read -r -p "$prompt [$suffix]: " answer; answer="${answer:-$default}"; [[ "$answer" =~ ^[YyIi]$ ]]; }
validate_domain(){ [[ "$1" =~ ^([A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+[A-Za-z]{2,63}$ ]]; }
validate_port(){ [[ "$1" =~ ^[0-9]+$ ]] && (( 1 <= 10#$1 && 10#$1 <= 65535 )); }
escape_env(){ local v="$1"; v=${v//\\/\\\\}; v=${v//\"/\\\"}; printf '"%s"' "$v"; }
set_env(){ local key="$1" value="$2" file="${3:-$ENV_FILE}" tmp; mkdir -p "$(dirname "$file")"; touch "$file"; chmod 600 "$file"; tmp="$(mktemp)"; awk -v k="$key" -v v="$(escape_env "$value")" 'BEGIN{done=0} $0 ~ "^" k "=" {if(!done){print k "=" v; done=1}; next} {print} END{if(!done) print k "=" v}' "$file" > "$tmp"; mv "$tmp" "$file"; chmod 600 "$file"; }
get_env(){ local key="$1" file="${2:-$ENV_FILE}" raw; [[ -f "$file" ]] || return 0; raw="$(grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true)"; raw="${raw#\"}"; raw="${raw%\"}"; printf '%s' "$raw"; }
compose(){ local args=(-f "$ROOT_DIR/compose.yaml"); [[ -f "$OVERRIDE_FILE" ]] && args+=(-f "$OVERRIDE_FILE"); docker compose "${args[@]}" --env-file "$ENV_FILE" "$@"; }
backup_file(){ [[ -f "$1" ]] && cp -a "$1" "$1.bak.$(date +%Y%m%d%H%M%S)"; }
