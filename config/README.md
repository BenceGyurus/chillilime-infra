# Szolgáltatáskonfigurációk

- [Traefik](traefik/README.md): HTTPS/TCP útvonalak és metrikaport.
- [Prometheus](prometheus/README.md): scrape targetek és riasztási szabályok.
- [Grafana](grafana/README.md): adatforrás és dashboard automatikus létrehozása.
- [Minecraft-proxy](mc-proxy/README.md): BungeeCord és Velocity konfigurációminták.

A fájlok felmásolását a megfelelő Terraform-modul végzi. A proxy mintákhoz jelenleg
nincs futtató Compose-service. A PVE-hitelesítési fájl és a runtime forwarding secret helyi titok.
