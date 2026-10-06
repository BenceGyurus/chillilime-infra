# Grafana provisioning

A `provisioning/datasources/prometheus.yml` létrehozza a `prometheus` UID-jú alapértelmezett
adatforrást a Docker-hálózaton elérhető `http://prometheus:9090` címmel.
A `provisioning/dashboards/default.yml` a `/etc/grafana/dashboards` könyvtárból tölti a dashboardot.

A `dashboards/overview.json` az Infrastructure mappában jelenik meg:
scrape állapot, CPU, memória, lemezhasználat, aktív riasztások és Traefik HTTP-kérések.
A Grafana felületén a dashboard és az adatforrás nem szerkeszthető; a forrásfájlokat módosítsd.

A provisioning fájlokat a monitoring Terraform-modul másolja fel, és a Compose read-only mountolja.
A Grafana felhasználói és saját adatbázisa a `grafana-data` volume-ban vannak.
A `GF_SECURITY_ADMIN_*` változók az első admin létrehozására szolgálnak;
meglévő adatbázisban az `.env` jelszómódosítása önmagában nem cseréli le az adminjelszót.

A `GF_SERVER_ROOT_URL` teljes URL legyen, például `https://grafana.chililime.hu/`.
A Traefik-route külön szükséges a domainen történő eléréshez.
A `http://10.1.1.4:3000/api/health` lekérdezés működő Grafanánál adatbázisállapotot ad vissza.
HTTP 404 a Traefiken át, miközben a közvetlen `/login` HTTP 200, útvonalhibára utal.
A startup `SQLITE_BUSY` újrapróbálkozás önmagában nem bizonyít tartós adatbázishibát;
a `/api/health` és az aktuális error-log együtt használható a diagnózishoz.
