# Vaultwarden LAU

Moduláris, interaktív Vaultwarden-telepítő Debian/Ubuntu szerverekhez. Kezeli a Docker telepítését, a meglévő vagy új reverse proxyt, SMTP-t, TLS-t, backupot, restore-t, frissítést és health checket.

> A projekt nem hivatalos Vaultwarden-termék. Használat előtt készíts biztonsági mentést, és olvasd el a Vaultwarden dokumentációját.


## LAU parancsok

```bash
sudo ./lau install
sudo ./lau status
sudo ./lau doctor
sudo ./lau update
sudo ./lau backup
sudo ./lau restore
sudo ./lau logs
sudo ./lau restart
```

A teljes diagnosztika dokumentációja: [`docs/DOCTOR.md`](docs/DOCTOR.md).

## Gyors indulás

```bash
git clone https://github.com/ceszes-hub/Vaultwarden-lau.git
cd Vaultwarden-lau
chmod +x install.sh lau scripts/*.sh lib/*.sh
sudo ./install.sh
```

Későbbi kezelés:

```bash
sudo ./lau
```

## Támogatott proxy módok

- meglévő Dockeres Nginx;
- meglévő hostos Nginx;
- meglévő HAProxy;
- automatikusan telepített hostos Nginx;
- proxy nélküli tesztmód.

## Fontos fájlok

- `install.sh`: egyszerű belépési pont;
- `lau`: kezelőmenü;
- `scripts/`: műveletek;
- `lib/`: újrahasznosítható modulok;
- `.env`: titkos konfiguráció, nem kerül Gitbe;
- `compose.override.yaml`: a kiválasztott hálózati mód.

## Biztonság

A `.env` jogosultsága `600`. Nyilvános regisztráció alapértelmezetten tiltott. Az admin token telepítéskor véletlenszerűen generálódik. A mentések titkos adatokat tartalmazhatnak, ezért védd őket és tárold külön gépen is.

## Tesztelés

```bash
bash -n install.sh lau scripts/*.sh lib/*.sh
docker compose --env-file .env.example -f compose.yaml config
shellcheck install.sh lau scripts/*.sh lib/*.sh
```

Részletek: `docs/`.
