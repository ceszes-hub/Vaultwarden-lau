#!/usr/bin/env bash
set -Eeuo pipefail

DOCTOR_OK=0
DOCTOR_WARN=0
DOCTOR_FAIL=0

_doctor_ok(){ ok "$*"; ((DOCTOR_OK+=1)); }
_doctor_warn(){ warn "$*"; ((DOCTOR_WARN+=1)); }
_doctor_fail(){ printf '%b[FAIL]%b %s\n' "$C_RED" "$C_RESET" "$*" >&2; ((DOCTOR_FAIL+=1)); }

check_os(){
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    case "${ID:-}" in
      ubuntu)
        case "${VERSION_ID:-}" in 22.04|24.04|26.04) _doctor_ok "Ubuntu ${VERSION_ID} támogatott.";; *) _doctor_warn "Ubuntu ${VERSION_ID:-ismeretlen}; tesztelt verziók: 22.04, 24.04, 26.04.";; esac
        ;;
      debian) _doctor_warn "Debian ${VERSION_ID:-ismeretlen}; várhatóan működik, de nem elsődlegesen támogatott.";;
      *) _doctor_warn "Nem tesztelt rendszer: ${PRETTY_NAME:-ismeretlen}.";;
    esac
  else
    _doctor_warn "Az operációs rendszer nem azonosítható (/etc/os-release hiányzik)."
  fi
}

check_docker(){
  if ! command_exists docker; then _doctor_fail "A Docker nincs telepítve."; return; fi
  _doctor_ok "Docker elérhető: $(docker --version 2>/dev/null | head -1)."
  if docker info >/dev/null 2>&1; then _doctor_ok "A Docker daemon fut és elérhető."; else _doctor_fail "A Docker daemon nem érhető el; ellenőrizd a szolgáltatást és a jogosultságokat."; fi
  if docker compose version >/dev/null 2>&1; then _doctor_ok "Docker Compose plugin elérhető: $(docker compose version --short 2>/dev/null)."; else _doctor_fail "A Docker Compose plugin nem érhető el."; fi
}

check_files(){
  [[ -f "$ROOT_DIR/compose.yaml" ]] && _doctor_ok "compose.yaml megtalálható." || _doctor_fail "compose.yaml hiányzik."
  if [[ -f "$ENV_FILE" ]]; then
    _doctor_ok ".env megtalálható."
    mode="$(stat -c '%a' "$ENV_FILE" 2>/dev/null || true)"
    [[ "$mode" == 600 || "$mode" == 400 ]] && _doctor_ok ".env jogosultsága megfelelő ($mode)." || _doctor_warn ".env jogosultsága ${mode:-ismeretlen}; javasolt: chmod 600 .env"
  else
    _doctor_fail ".env hiányzik; futtasd a telepítőt."
  fi
}

check_compose_config(){
  [[ -f "$ENV_FILE" ]] || return
  if compose config --quiet >/dev/null 2>&1; then _doctor_ok "A Docker Compose konfiguráció érvényes."; else _doctor_fail "A Docker Compose konfiguráció hibás; futtasd: docker compose config"; fi
}

check_container(){
  command_exists docker || return
  local container status health
  container="$(get_env CONTAINER_NAME)"; container="${container:-vaultwarden}"
  if ! docker inspect "$container" >/dev/null 2>&1; then _doctor_fail "A(z) $container konténer nem található."; return; fi
  status="$(docker inspect --format '{{.State.Status}}' "$container" 2>/dev/null || true)"
  health="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$container" 2>/dev/null || true)"
  [[ "$status" == running ]] && _doctor_ok "A(z) $container konténer fut." || _doctor_fail "A(z) $container konténer állapota: ${status:-ismeretlen}."
  case "$health" in healthy) _doctor_ok "A konténer health checkje sikeres.";; starting) _doctor_warn "A konténer health checkje még indul.";; unhealthy) _doctor_fail "A konténer health checkje sikertelen.";; '') _doctor_warn "A konténerhez nincs health státusz.";; esac
}

check_disk(){
  local path data_dir avail_kb avail_gb
  data_dir="$(get_env DATA_DIR)"; data_dir="${data_dir:-$ROOT_DIR/data}"
  [[ "$data_dir" = /* ]] && path="$data_dir" || path="$ROOT_DIR/${data_dir#./}"
  [[ -e "$path" ]] || path="$ROOT_DIR"
  avail_kb="$(df -Pk "$path" 2>/dev/null | awk 'NR==2 {print $4}')"
  [[ "$avail_kb" =~ ^[0-9]+$ ]] || { _doctor_warn "A szabad lemezterület nem mérhető."; return; }
  avail_gb=$((avail_kb / 1024 / 1024))
  if (( avail_gb >= 5 )); then _doctor_ok "Szabad lemezterület: ${avail_gb} GiB."; elif (( avail_gb >= 1 )); then _doctor_warn "Kevés szabad lemezterület: ${avail_gb} GiB."; else _doctor_fail "Kritikusan kevés szabad lemezterület: ${avail_gb} GiB."; fi
}

check_ports(){
  local port state
  for port in 80 443; do
    if command_exists ss; then
      state="$(ss -H -ltn "sport = :$port" 2>/dev/null | head -1 || true)"
      [[ -n "$state" ]] && _doctor_ok "A TCP/$port porton szolgáltatás figyel." || _doctor_warn "A TCP/$port porton nem figyel szolgáltatás."
    else
      _doctor_warn "Az ss parancs hiányzik; a TCP/$port port nem ellenőrizhető."
    fi
  done
}

_normalize_domain(){ local d="$1"; d="${d#http://}"; d="${d#https://}"; d="${d%%/*}"; printf '%s' "$d"; }

check_dns(){
  local raw domain resolved public_ip
  raw="$(get_env DOMAIN)"; [[ -n "$raw" ]] || { _doctor_warn "DOMAIN nincs beállítva."; return; }
  domain="$(_normalize_domain "$raw")"
  if command_exists getent; then resolved="$(getent ahostsv4 "$domain" 2>/dev/null | awk 'NR==1 {print $1}')"; else resolved=""; fi
  [[ -n "$resolved" ]] && _doctor_ok "DNS feloldás: $domain → $resolved" || { _doctor_fail "A domain nem oldható fel: $domain"; return; }
  if command_exists curl; then
    public_ip="$(curl -4fsS --max-time 5 https://api.ipify.org 2>/dev/null || true)"
    [[ -z "$public_ip" ]] && _doctor_warn "A publikus IP-cím nem kérdezhető le." || { [[ "$resolved" == "$public_ip" ]] && _doctor_ok "A DNS a szerver publikus IP-címére mutat." || _doctor_warn "DNS: $resolved, szerver publikus IP: $public_ip. NAT/proxy esetén ez lehet helyes."; }
  fi
}

check_http_tls(){
  local raw url code domain expiry epoch now days
  raw="$(get_env DOMAIN)"; [[ -n "$raw" ]] || return
  [[ "$raw" =~ ^https?:// ]] && url="$raw" || url="https://$raw"
  if command_exists curl; then
    code="$(curl -LsS -o /dev/null -w '%{http_code}' --max-time 12 "$url/alive" 2>/dev/null || true)"
    [[ "$code" =~ ^(2|3)[0-9][0-9]$ ]] && _doctor_ok "Vaultwarden HTTP ellenőrzés: $code ($url/alive)." || _doctor_fail "Vaultwarden HTTP ellenőrzés sikertelen: ${code:-kapcsolati hiba} ($url/alive)."
  else _doctor_warn "A curl hiányzik; HTTP ellenőrzés kihagyva."; fi
  domain="$(_normalize_domain "$raw")"
  if command_exists openssl && timeout 12 openssl s_client -connect "$domain:443" -servername "$domain" </dev/null >/tmp/lau-doctor-tls.$$ 2>/dev/null; then
    expiry="$(openssl x509 -noout -enddate </tmp/lau-doctor-tls.$$ 2>/dev/null | cut -d= -f2-)"; rm -f /tmp/lau-doctor-tls.$$
    if [[ -n "$expiry" ]]; then epoch="$(date -d "$expiry" +%s 2>/dev/null || true)"; now="$(date +%s)"; if [[ "$epoch" =~ ^[0-9]+$ ]]; then days=$(((epoch-now)/86400)); (( days >= 30 )) && _doctor_ok "TLS-tanúsítvány még $days napig érvényes." || { (( days >= 7 )) && _doctor_warn "TLS-tanúsítvány $days nap múlva lejár." || _doctor_fail "TLS-tanúsítvány $days nap múlva lejár vagy már lejárt."; }; fi; fi
  else _doctor_warn "A TLS-tanúsítvány nem ellenőrizhető."; rm -f /tmp/lau-doctor-tls.$$; fi
}

check_backups(){
  local backup_dir latest age now mtime
  backup_dir="$(get_env BACKUP_DIR)"; backup_dir="${backup_dir:-$ROOT_DIR/backups}"
  [[ "$backup_dir" = /* ]] || backup_dir="$ROOT_DIR/${backup_dir#./}"
  if [[ ! -d "$backup_dir" ]]; then _doctor_warn "Backup könyvtár nem található: $backup_dir"; return; fi
  latest="$(find "$backup_dir" -maxdepth 1 -type f -printf '%T@ %p\n' 2>/dev/null | sort -nr | awk 'NR==1 {$1=""; sub(/^ /,""); print}' || true)"
  [[ -n "$latest" ]] || { _doctor_warn "Nem található backup a következő helyen: $backup_dir"; return; }
  mtime="$(stat -c '%Y' "$latest" 2>/dev/null || echo 0)"; now="$(date +%s)"; age=$(((now-mtime)/86400))
  (( age <= 7 )) && _doctor_ok "Legutóbbi backup: $age napos ($(basename "$latest"))." || _doctor_warn "A legutóbbi backup $age napos ($(basename "$latest"))."
}

run_doctor(){
  info "Vaultwarden LAU diagnosztika indul..."
  check_os; check_files; check_docker; check_compose_config; check_container; check_disk; check_ports; check_dns; check_http_tls; check_backups
  printf '\nÖsszesítés: %b%d rendben%b, %b%d figyelmeztetés%b, %b%d hiba%b\n' "$C_GREEN" "$DOCTOR_OK" "$C_RESET" "$C_YELLOW" "$DOCTOR_WARN" "$C_RESET" "$C_RED" "$DOCTOR_FAIL" "$C_RESET"
  (( DOCTOR_FAIL == 0 ))
}
