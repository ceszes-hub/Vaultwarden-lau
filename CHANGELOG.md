# Changelog


## [1.3.1] - 2026-07-27

### Fixed
- Javítva a `lib/ssl.sh` idézőjel- és parse hibája.
- Az SC2015 rövidzáras feltételek explicit `if` blokkokra cserélve.
- Javítva az SC2155 és SC2086 ShellCheck figyelmeztetés.
- A health check HTTP státuszkód-ellenőrzése pontosítva.

## [1.3.0] - 2026-07-27

### Added
- Új `lau <parancs>` parancssori felület.
- `lau doctor` teljes rendszerdiagnosztika.
- OS, Docker, Compose, konténer, lemez, port, DNS, HTTP, TLS és backup ellenőrzések.
- Géppel feldolgozható kilépési kód a diagnosztikához.
- Külön `docs/DOCTOR.md` dokumentáció.

### Changed
- Az interaktív menü közvetlenül elérhető a `lau menu` paranccsal.

## 1.2.0 - 2026-07-27

- moduláris telepítőarchitektúra;
- új pre-flight riport és proxyfelismerés;
- biztonságosabb `.env` kezelés;
- idempotens belépési pont és kezelőmenü;
- SMTP- és Certbot-varázsló;
- backup, restore, update és health check fejlesztések;
- kibővített dokumentáció és CI.

## 1.1.0

- első GitHubra kész változat.
