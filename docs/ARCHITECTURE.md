# Architektúra

Az `install.sh` csak a `scripts/install.sh` belépési pontja. A telepítési folyamat moduljai a `lib/` könyvtárban vannak:

- `common.sh`: naplózás, promptok, `.env`, Compose wrapper;
- `detect.sh`: OS-, port-, DNS- és proxyfelismerés;
- `docker.sh`: Docker előfeltétel;
- `config.sh`: alap Vaultwarden-beállítások;
- `proxy.sh`: hálózati mód és konfigurációs minták;
- `smtp.sh`: SMTP-varázsló;
- `ssl.sh`: Certbot-integráció.

A karbantartási műveletek külön scriptként és a `lau` menüből is elérhetők.
