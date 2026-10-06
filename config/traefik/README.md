# Traefik

A [loadbalancer Terraform-modul](../../terraform/loadbalancer/README.md) telepíti.

| Fájl | Tartalom |
| --- | --- |
| `traefik.yml` | statikus konfiguráció: entrypointok, file provider, Prometheus, ACME |
| `mc.yml` | Crafty HTTPS-router és Minecraft TCP-router |
| `services.yml` | Grafana HTTPS-router |
| `dashboard.yml` | külön Traefik dashboard-route minta; a Terraform nem másolja fel |

A statikus konfiguráció `/etc/traefik/traefik.yml`, a dinamikus fájlok
`/etc/traefik/dynamic/` alatt vannak. A routerneveknek fájlokon át is egyedieknek kell lenniük:
Crafty `mc-router`, Grafana `grafana-router`.

Portok: `80` HTTP→HTTPS átirányítás, `443` HTTPS, `25565` Minecraft TCP,
`9101` Prometheus metrikák. A Minecraft TCP-router minden SNI-t elfogad;
a backend mc-router feladata a Minecraft-hostnév szerinti szétosztás.

A Grafana backend `http://10.1.1.4:3000`, a Crafty backend `https://10.1.1.3:8443`.
A Crafty backend TLS-ellenőrzése explicit ki van kapcsolva a belső kapcsolatnál.
A Grafana publikus root URL-je `https://grafana.chililime.hu/` legyen.

A Let's Encrypt TLS-ALPN challenge a kívülről elérhető 443-as portot igényli.
Ha előtte más rendszer terminálja a TLS-t, a challenge nem feltétlenül jut el Traefikhez.
Az `/etc/traefik/acme.json` privát kulcsokat tartalmaz, nem commitolható.
A `dashboard.yml` route nem tartalmaz hitelesítést, és a `web` entrypoint globálisan átirányít;
nyilvános dashboardhoz ezt külön kell megfelelően kialakítani.

A statikus konfiguráció módosítása újraindítást igényel; a dinamikus fájlokat a file provider figyeli.
Az Ansible metrikaszabályok csak `10.1.1.4` számára engedik a `9100/9101` portokat.
