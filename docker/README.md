# Docker szolgáltatások

Két külön Compose-projekt van:

- [Crafty / Minecraft](crafty/README.md): Crafty, mc-router és PostgreSQL a Minecraft VM-en.
- [Monitoring](monitoring/README.md): Prometheus, Grafana és API-exporterek a monitoring VM-en.

A Terraform másolja fel a Compose fájlokat és készíti elő a futtatási könyvtárakat.
A szolgáltatások adatai és a helyi `.env` fájlok nem kerülhetnek GitHubra.
A `docker compose config --quiet` csak a Compose-konfigurációt ellenőrzi;
nem ellenőrzi az API-k elérhetőségét és nem indít konténert.
