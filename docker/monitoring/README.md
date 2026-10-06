# Monitoring

A stack a `10.1.1.4` monitoring VM-re kerül. A Terraform másolja fel a konfigurációkat;
önmagában a repositoryban lévő Compose fájl nem készíti elő a VM-et.

## Előkészített funkciók

- Prometheus: saját állapot, Proxmox, OPNsense, a két VM node-exportere, a loadbalancer node-exportere és Traefik.
- Grafana: automatikus Prometheus-adatforrás és az Infrastructure / Chillilime Infrastructure dashboard.
- Riasztások: legalább 2 perce elérhetetlen target, 5 perce 10% alatti szabad memória vagy szabad lemezterület.
- A riasztások a Prometheus `/alerts` oldalán és a Grafana dashboard Active alerts paneljén látszanak. Külső értesítés nincs beállítva.

## Telepítés előfeltételei

- `docker/monitoring/.env`: Grafana adminfelhasználó, jelszó, root URL és OPNsense API-kulcsok.
- `config/prometheus/pve.yml`: `default` modul működő Proxmox-hitelesítéssel.
- A cloud-init template-ben működő SSH és jelszó nélküli sudo a Terraform SSH-felhasználójának.
- A monitoring VM eléri a `10.1.1.1` OPNsense API-t, a `10.1.1.2:8006` Proxmox API-t,
  a `10.1.1.3:9100` node-exportert és a `10.1.1.254:9100/9101` metrikaportokat.
- Az OPNsense API-felhasználónak megvannak az exporter által megkövetelt jogosultságai.
  HTTPS esetén a tanúsítványának érvényesnek és a konténer által megbízhatónak kell lennie;
  a tanúsítvány-ellenőrzést nem kapcsoljuk ki automatikusan.
- A loadbalancerhez az Ansible tűzfalszabályok alkalmazása is szükséges. Ezek a metrikaportokat csak a monitoring VM számára engedik.

A monitoring és Minecraft Terraform-modul készíti elő a VM-exportereket;
a loadbalancer modul telepíti a repository Traefik-konfigurációját és a saját node-exporterét.
A Terraform későbbi `apply` művelete szolgáltatásokat indít és a monitoring konténereit újralétrehozza.

## Ellenőrzés indítás nélkül

A repository gyökeréből:

```sh
docker compose --env-file docker/monitoring/.env -f docker/monitoring/docker-compose.yml config --quiet
terraform fmt -check terraform/monitoring/main.tf terraform/mc/main.tf terraform/loadbalancer/main.tf
bash -n scripts/docker.sh scripts/traefik.sh
```

A Terraform `validate` helyi, telepített providereket igényel; nem telepít infrastruktúrát.
A VM-en a Prometheus-config `/home/monitoring/prometheus/prometheus.yml`, a PVE-config
`/home/monitoring/pve-exporter/pve.yml`, a Grafana-fájlok `/home/monitoring/grafana/` alatt lesznek.
A PVE-hitelesítési fájl a hivatalos exporter 101-es UID-jához kap 0600 jogosultságot.

## Adatok és későbbi ellenőrzés

A Prometheus és Grafana adatai Docker named volume-okba kerülnek. Korábban használt
`./prometheus` vagy `./grafana` adatkönyvtár tartalmát ez nem migrálja automatikusan;
ha vannak megtartandó adatok, azokat az első indítás előtt külön át kell költöztetni.
A Grafana provisioning fájljai és a dashboard a repositoryban szerkeszthetők.

A későbbi indítás után a Prometheus `/targets` oldalon minden targetnek `UP` állapotúnak
kell lennie. Az API-jogosultságok és a tényleges hálózati elérés csak ekkor igazolható.
Az OPNsense-exporter elérhetősége önmagában nem bizonyítja minden collector sikerét;
a logjait és a begyűjtött metrikákat is ellenőrizni kell.

Mivel a monitoring ugyanazon a Proxmox-gépen fut, a teljes host kiesésekor a saját
felületét sem lehet elérni. Külső kiesésérzékeléshez később külön megfigyelő szükséges.

## Grafana hibaelhárítás indítás nélkül

A monitoring VM-en a következők csak olvasási ellenőrzések:

```sh
curl --fail --silent --show-error http://127.0.0.1:3000/api/health
curl --silent --output /dev/null --write-out '%{http_code}\n' http://127.0.0.1:3000/login
docker compose -f /home/monitoring/docker-compose.yml ps
```

Ha a közvetlen login HTTP 200, de a publikus domainen HTTP 404 érkezik,
ellenőrizd a Traefik `services.yml` betöltését és a `grafana-router` egyedi nevét.
A Minecraft `mc-router` nevét a Grafana-route nem használhatja.
A futó Grafana `GF_SERVER_ROOT_URL` értéke teljes HTTPS URL legyen;
helyi `.env` módosítása a már futó konténer konfigurációját nem írja át.
A startup SQLite-zárolási újrapróbálkozások helyett az aktuális health-állapotot
és tartós error-logokat vizsgáld. A [Grafana konfigurációleírása](../../config/grafana/README.md)
további részleteket tartalmaz.
