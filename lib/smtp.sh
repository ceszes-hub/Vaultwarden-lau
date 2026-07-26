#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

smtp_wizard() {
  echo
  echo "SMTP szolgáltató:"
  echo "1) Gmail"
  echo "2) Microsoft 365 / Office 365"
  echo "3) Egyedi SMTP"
  echo "4) Később az Admin Portalon"
  read -r -p "Választás [4]: " choice
  choice="${choice:-4}"
  [[ "$choice" == "4" ]] && { set_env SMTP_ENABLED false; return; }

  local host port security from username password mechanism
  case "$choice" in
    1) host="smtp.gmail.com"; port="587"; security="starttls"; mechanism="Login" ;;
    2) host="smtp.office365.com"; port="587"; security="starttls"; mechanism="Login" ;;
    3)
      host="$(prompt_default 'SMTP host' 'smtp.example.com')"
      port="$(prompt_default 'SMTP port' '587')"
      security="$(prompt_default 'Biztonság (starttls/force_tls/off)' 'starttls')"
      mechanism="$(prompt_default 'Auth mechanizmus' 'Login')"
      ;;
    *) die "Érvénytelen választás." ;;
  esac
  from="$(prompt_default 'Feladó e-mail cím' 'vault@example.com')"
  username="$(prompt_default 'SMTP felhasználónév' "$from")"
  read -r -s -p "SMTP jelszó / alkalmazásjelszó: " password; echo

  set_env SMTP_ENABLED true
  set_env SMTP_HOST "$host"
  set_env SMTP_PORT "$port"
  set_env SMTP_SECURITY "$security"
  set_env SMTP_FROM "$from"
  set_env SMTP_FROM_NAME "Vaultwarden"
  set_env SMTP_USERNAME "$username"
  set_env SMTP_PASSWORD "$password"
  set_env SMTP_AUTH_MECHANISM "$mechanism"
  set_env SMTP_TIMEOUT 15
}
