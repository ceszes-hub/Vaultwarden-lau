#!/usr/bin/env bash
set -Eeuo pipefail
# shellcheck source=lib/common.sh
source "${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/common.sh"
configure_smtp_values(){ local host="$1" port="$2" security="$3" from="$4" name="$5" user="$6" pass="$7"; set_env SMTP_HOST "$host"; set_env SMTP_PORT "$port"; set_env SMTP_SECURITY "$security"; set_env SMTP_FROM "$from"; set_env SMTP_FROM_NAME "$name"; set_env SMTP_USERNAME "$user"; set_env SMTP_PASSWORD "$pass"; }
smtp_wizard(){ local choice email password host port security from name user; echo; cat <<'MENU'
SMTP:
1) Gmail
2) Microsoft 365
3) Egyedi SMTP
4) Kihagyás / admin panelben később
MENU
  read -r -p "Választás [4]: " choice; choice="${choice:-4}"
  case "$choice" in
    1) email="$(prompt_default 'Gmail-cím' 'admin@example.com')"; password="$(prompt_secret 'Google App Password')"; [[ -n "$password" ]] || die "Az App Password nem lehet üres."; configure_smtp_values smtp.gmail.com 587 starttls "$email" 'Vaultwarden' "$email" "$password";;
    2) email="$(prompt_default 'Microsoft 365 e-mail' 'admin@example.com')"; password="$(prompt_secret 'SMTP-jelszó')"; [[ -n "$password" ]] || die "A jelszó nem lehet üres."; configure_smtp_values smtp.office365.com 587 starttls "$email" 'Vaultwarden' "$email" "$password";;
    3) host="$(prompt_default 'SMTP host' 'smtp.example.com')"; port="$(prompt_default 'SMTP port' '587')"; security="$(prompt_default 'Biztonság (starttls/force_tls/off)' 'starttls')"; from="$(prompt_default 'Feladó e-mail' 'vaultwarden@example.com')"; name="$(prompt_default 'Feladó neve' 'Vaultwarden')"; user="$(prompt_default 'Felhasználónév' "$from")"; password="$(prompt_secret 'SMTP-jelszó')"; configure_smtp_values "$host" "$port" "$security" "$from" "$name" "$user" "$password";;
    4) info "SMTP kihagyva.";;
    *) die "Érvénytelen választás.";;
  esac
}
