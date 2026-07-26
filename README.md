# Vaultwarden LAU

Interaktív, Docker Compose-alapú Vaultwarden telepítő és karbantartó eszköz Ubuntu/Debian rendszerekhez.

## Támogatott reverse proxy módok

- meglévő Dockeres Nginx
- meglévő hostos Nginx
- meglévő HAProxy
- Nginx automatikus telepítése
- proxy nélküli tesztmód

A telepítő megpróbálja felismerni a már futó proxykat, de a rendszergazda választja ki a használandó módot.

## Gyors indítás

```bash
git clone https://github.com/ceszes-hub/Vaultwarden-lau.git
cd Vaultwarden-lau
chmod +x lau scripts/*.sh lib/*.sh
sudo ./lau
```

## Biztonság

A `.env`, a trezoradatok és a mentések Gitből ki vannak zárva. Az admin tokent a telepítő automatikusan generálja. A korábban megosztott vagy naplóba került tokeneket azonnal cserélni kell.

## SMTP

A telepítő Gmail, Microsoft 365 és egyedi SMTP beállítást kínál. Gmailhez kétlépcsős azonosítás és alkalmazásjelszó szükséges. SMTP később a Vaultwarden `/admin` felületén is módosítható.

## Parancsok

```bash
./lau
./scripts/health.sh
./scripts/backup.sh
./scripts/update.sh
./scripts/restore.sh backups/vaultwarden-DATUM.tar.gz
```

## TLS

Az automatikus Nginx-telepítés létrehozza a HTTP virtual hostot. A TLS-t a környezethez illeszkedő módon kell kiadni, például Certbottal, acme.sh-val, DNS challenge-dzsel vagy meglévő tanúsítvánnyal.
