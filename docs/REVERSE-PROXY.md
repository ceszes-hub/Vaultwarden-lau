# Reverse proxy

Hostos Nginx és HAProxy esetén a Vaultwarden alapértelmezetten csak `127.0.0.1:8080` címen hallgat. Dockeres Nginx esetén nincs host port, a proxy a közös Docker-hálózaton a `vaultwarden:80` címet használja.

A generált mintákat élesítés előtt ellenőrizd. TLS-termináció, HSTS, CSP és egyéb szervezeti biztonsági előírások a reverse proxy felelőssége.
