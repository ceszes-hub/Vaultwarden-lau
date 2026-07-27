#!/usr/bin/env bash
set -Eeuo pipefail
# shellcheck source=lib/common.sh
source "${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/common.sh"
ssl_wizard(){ local domain="$1" mode="$(get_env PROXY_MODE)" choice email; [[ "$mode" == none ]] && return 0; echo; cat <<'MENU'
TLS/SSL:
1) Let's Encrypt Certbot (hostos/telepített Nginx)
2) Meglévő proxy vagy tanúsítvány kezeli
3) Később állítom be
MENU
  read -r -p "Választás [2]: " choice; choice="${choice:-2}"
  case "$choice" in
    1) [[ "$mode" == host-nginx || "$mode" == install-nginx ]] || { warn "Automatikus Certbot csak hostos Nginxnél támogatott."; return; }; require_root; email="$(prompt_default 'Let's Encrypt e-mail' 'admin@example.com')"; apt-get update; apt-get install -y certbot python3-certbot-nginx; certbot --nginx -d "$domain" --non-interactive --agree-tos -m "$email" --redirect; ok "TLS tanúsítvány beállítva.";;
    2) info "A meglévő proxy/tanúsítvány kezeli a TLS-t.";;
    3) warn "TLS nincs automatikusan konfigurálva.";;
    *) die "Érvénytelen választás.";;
  esac
}
