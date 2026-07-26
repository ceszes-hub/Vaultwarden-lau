# Reverse proxy módok

## Dockeres Nginx
A Vaultwarden és a proxy ugyanarra a külső Docker-hálózatra kerül. A backend címe `vaultwarden:80`.

## Hostos Nginx
A Vaultwarden csak a `127.0.0.1:8080` címen figyel. A generált Nginx fájl az `nginx/` könyvtárba kerül.

## HAProxy
A Vaultwarden csak a `127.0.0.1:8080` címen figyel. A generált HAProxy-részlet a `haproxy/` könyvtárba kerül.

## Automatikus Nginx
A telepítő apt segítségével telepíti az Nginxet, létrehozza a virtual hostot, ellenőrzi a konfigurációt és újratölti a szolgáltatást. A TLS kiadása külön lépés.
