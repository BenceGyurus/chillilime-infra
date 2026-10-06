# Prometheus

- `prometheus.yml`: 10 másodperces scrape/evaluation intervallum és targetek.
- `alerts.yml`: kiesés-, memória- és lemezriasztások.
- `pve.yml`: helyi Proxmox-hitelesítés, Gitből kizárva; minta: `pve.example.yml`.

A Terraform a fájlokat `/home/monitoring/prometheus/` és `/home/monitoring/pve-exporter/`
alá másolja; a Compose innen mountolja őket. A Prometheus-adatok külön named volume-on vannak.

A PVE-job a `10.1.1.2` targetet a `/pve` kérés paraméterévé alakítja,
a tényleges lekérdezést a `pve-exporter:9221` szolgáltatáshoz küldi.
A PVE-exporter `default` modulja a helyi `pve.yml` fájlban szükséges.
A többi target a saját Prometheus, OPNsense-exporter, két VM node-exportere,
a loadbalancer node-exportere és Traefik metrikavégpontja.

A `MonitoringTargetDown` 2 perc után, a memória- és lemezriasztás 5 percen át
10% alatti szabad kapacitásnál aktiválódik. A csak olvasható és átmeneti fájlrendszerek
nem okoznak lemezriasztást. A szabályok külső értesítést nem küldenek.

Működés közben `/targets`: scrape állapot, `/alerts`: pending/firing riasztások.
A Prometheus `/metrics` végpontja a saját metrikáit mutatja, nem az összes exporterét.
