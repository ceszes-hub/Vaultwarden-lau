# Backup és restore

Mentés:

```bash
sudo ./scripts/backup.sh
```

Visszaállítás:

```bash
sudo ./scripts/restore.sh backups/vaultwarden-YYYYMMDD-HHMMSS.tar.gz
```

A backup tartalmazza a `data/`, `.env` és `compose.override.yaml` fájlokat. Titkos adat, ezért titkosított, elkülönített tárhelyen is őrizd. A restore előtt a jelenlegi `data/` könyvtár időbélyeges néven megmarad.
