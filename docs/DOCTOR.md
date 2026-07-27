# `lau doctor`

A `lau doctor` átfogó, csak olvasási műveleteket végző diagnosztika. Nem módosítja a telepítést.

```bash
sudo ./lau doctor
```

Ellenőrzések:

- operációs rendszer és támogatott Ubuntu-verzió;
- `compose.yaml`, `.env` és annak fájljogosultsága;
- Docker daemon és Docker Compose plugin;
- Compose-konfiguráció érvényessége;
- Vaultwarden konténer futási és health státusza;
- szabad lemezterület;
- TCP/80 és TCP/443 figyelő szolgáltatás;
- domain DNS-feloldása és publikus IP összevetése;
- `/alive` HTTP-végpont;
- TLS-tanúsítvány lejárata;
- legutóbbi backup kora.

## Kilépési kód

- `0`: nincs kritikus hiba; figyelmeztetések lehetnek;
- `1`: legalább egy kritikus ellenőrzés sikertelen.

Ez alkalmassá teszi cronból, monitoringból vagy CI-ből történő használatra is.
