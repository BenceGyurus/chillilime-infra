# Forgejo és Debian runner

Önálló Terraform root modul a meglévő `bpg/proxmox` + SSH provisioner mintával.
Mindkét VM a `chililime` node 100-as **Debian cloud-init template-jéből** készül,
`vmbr1` bridge-en, `<PRIVATE_ADDRESS>` gateway-jel.

| VM | ID | IP | CPU / RAM | Lemez |
| --- | --- | --- | --- | --- |
| Forgejo | 104 | `<PRIVATE_ADDRESS>/24` | 2 / 2 GiB | `scsi0`: 15 GiB, `vm-disk1` |
| Forgejo adat | ugyanaz | ugyanaz | — | `scsi1`: 50 GiB, `storage-mirror` |
| Debian runner | privát konfiguráció | privát konfiguráció | 10 / 16 GiB, host CPU / KVM | `scsi0`: 80 GiB, `vm-disk1` |

A runner külön VM, a saját rendszerlemezén tárolja a Docker image-eket,
munkakönyvtárakat és regisztrációt. A cloud-init lemezek is `vm-disk1`-re kerülnek.
Az ID-k, IP-k, Forgejo domain és URL változókkal felülírhatók.

## Előfeltételek és telepítés

- A `storage-mirror` létező, VM image-eket támogató Proxmox datastore legyen.
- A template rendszerlemeze legfeljebb **15 GiB** legyen: klónozáskor a lemez
  növelhető, zsugorítani nem lehet. A template root fájlrendszerét a cloud-init növelje.
- A 104/105 ID-k és a két IP legyen szabad; telepítés előtt ellenőrizd őket.
- A template-ben cloud-init, QEMU guest agent, SSH és jelszó nélküli sudo szükséges.
- Helyi `~/.ssh/id_ed25519` kulcspár, elérhető Proxmox API és VM SSH szükséges.
- A VM-eknek internet kell az APT repositorykhoz és konténerregistrykhez.
- A `docker/forgejo/.env` fájl is szükséges, a mellette lévő `.env.template`
  alapján készíthető. Ez a Compose beállítása; külön fájl a Terraform hitelesítési `.env`-jétől.

```sh
cd terraform/forgejo
cp .env.template .env
# Töltsd ki a .env hitelesítési és SSH-felhasználó adatait.
set -a
source .env
set +a
terraform init
terraform validate
terraform plan
terraform apply
```

A `plan` során ellenőrizd a tárolókat, ID-kat és méreteket. Az `apply` létrehozza
a VM-eket, telepíti a Dockert és node-exportert, majd elindítja a Forgejót.
A runner image-ét letölti, de első regisztráció előtt nem indít daemont.
A fájlhash-ek követik a konfigurációváltozásokat; a VM cseréje új provisionálást kér.

## Adatlemez

A `scripts/forgejo-storage.sh` kizárólag a `forgejo-data` sorozatszámú `scsi1`
lemezt használja. Üres, partíció és aláírás nélküli lemezen ext4 fájlrendszert készít,
meglévő ext4-et megőriz; egyéb tartalomnál leáll. UUID alapján `/srv/forgejo` alá
csatolja, és Docker systemd mount-függőséget állít be. Hiányzó adatlemez esetén
a Docker nem indulhat el az OS-lemezen létrehozott pótló adatkönyvtárral.

A teljes Forgejo `/data` könyvtár a `/srv/forgejo/data` bind mountra kerül:
repositoryk, SQLite adatbázis, konfiguráció, LFS, csomagok és Actions adatok.
Az 50 GiB a teljes adatlemez mérete; az ext4 metaadatai és fenntartott blokkjai
miatt a hasznos kapacitás kisebb. A Docker image-ek és korlátozott konténerlogok
a Forgejo 15 GiB-os rendszerlemezén maradnak.

A VM törlése az adatlemezt is törölheti. Készíts külön mentést a teljes adatlemezről;
a mirror nem helyettesíti a backupot. SQLite fájlmentés előtt állítsd le a Forgejót.

## TuriLoki runner átállítás (2026-10-07)

A `Turiloki` szervezet szervezetszintű `turiloki-org-debian` runnere minden engedélyezett
szervezeti repó Actions jobját felveheti. A személyes felhasználóhoz tartozó runner
nem veszi fel a szervezet jobjait. A jelenlegi
regisztráció a VM-en a `/opt/forgejo-runner/config.yml` `server.connections`
részében van, a privát konfigurációban tárolt HTTPS URL-lel. A fájl root-only titok;
a mentés `/opt/forgejo-runner/backups/codex-20261007/` alatt található.

A provisioning a titokmentes sablont `config.template.yml` néven tölti fel,
majd a `scripts/forgejo-runner-config.py` megőrzi a meglévő regisztrációt és az
ismeretlen beállításokat; az eredmény módja 0600. Regisztrált modern és régi
`.runner` fájlos runner esetén is elindítja a szolgáltatást.

A helyi CI-image-eket a TuriLoki repó `scripts/ci/Dockerfile` és
`Dockerfile.android` fájljaiból kell felépíteni a runner VM-en. Címkék:
`debian:docker://turiloki-ci:node22-bookworm-v1` és
`debian-android:docker://turiloki-android:node22-sdk36-v1`.
Az Android jobhoz `/dev/kvm` átadás szükséges. A Terraform csak a jelenlegi
6 vCPU / 12 GiB / host CPU beállítást tükrözi; az átállítás során apply nem futott.

A runner kapacitása összesen 4 job, a maximális jobidő 6 óra. A rendszerlemez 2026-10-07-én
80 GiB-ra bővült; a vendég ext4 fájlrendszere online lett megnövelve.

## Első Forgejo-beállítás és runner-regisztráció

1. Nyisd meg a `http://<PRIVATE_ADDRESS>:3000/` címet, fejezd be a telepítést SQLite-tal,
   és az első beállítás során hozz létre adminisztrátort. Az adatbázis útvonala
   `/data/forgejo/forgejo.db`. A nyilvános felhasználóregisztráció ki van kapcsolva.
2. Az adminisztráció Actions / Runners részében kérj runner-regisztrációs tokent.
3. SSH-val lépj be a runner VM-re, majd regisztráld interaktívan:

```sh
cd /opt/forgejo-runner
sudo docker compose run --rm runner forgejo-runner register --config /etc/forgejo-runner/config.yml
# Instance: http://<PRIVATE_ADDRESS>:3000/
# Token: a Forgejo felületén kapott token
# Name: debian-runner
# Labels: debian:docker://node:22-bookworm
sudo docker compose up -d
sudo docker compose logs --tail=100 runner
```

A regisztráció a runner `/var/lib/forgejo-runner/.runner` fájljában marad meg,
és új provisionálás után is használható. Ez titok, ne másold Gitbe.
A runner a saját VM Docker socketjét használja; csak megbízható projektekhez rendeld.
Egyszerre egy job futhat, Debian Bookworm alapú Node 22 konténerben.
Az Actions-t a repository beállításai között is engedélyezni kell.

Ellenőrző workflow a Forgejo repository `.forgejo/workflows/check.yml` fájljába:

```yaml
name: Debian runner check
on: [push, workflow_dispatch]
jobs:
  check:
    runs-on: debian
    steps:
      - run: cat /etc/os-release && node --version
```

## Elérés

- Web: `http://<PRIVATE_ADDRESS>:3000/`
- Git SSH: `ssh://git@<PRIVATE_ADDRESS>:2222/<owner>/<repo>.git`
- VM admin SSH: a megszokott 22-es port, mindkét VM-en.
- Node-exporter: 9100-as port, mindkét VM-en. Prometheus targetet külön kell felvenni.

Domain vagy reverse proxy esetén állítsd együtt a `forgejo_domain` és
`forgejo_root_url` változókat, és gondoskodj a DNS-ről, TLS-ről és proxyútvonalról.
Az URL a runnerből és a job konténerekből is legyen elérhető. A beállításokat
a Terraform által generált `/opt/forgejo/compose.override.yml` adja át.
A feltöltött `/opt/forgejo/.env` `FORGEJO_DOMAIN` és `FORGEJO_ROOT_URL` értékei
felülírják ezeket az alapértékeket. Domain használatakor mindkettőt állítsd be.
Ilyenkor a Terraform `forgejo_url` outputja továbbra is a `forgejo_root_url`
Terraform-változót mutatja, ezért azt is tartsd összhangban az `.env` URL-jével.

A jelenlegi `config/traefik/services.yml` tartalmazza a `<FORGEJO_HOST>`
útvonalát, ideiglenesen csak belső IP-tartományokból engedélyezve és ACME nélkül.
Helyi használathoz a kliens hosts fájljában `<PRIVATE_ADDRESS> <FORGEJO_HOST>`
szerepeljen. A proxy a Forgejo `<PRIVATE_ADDRESS>:3000` címére továbbít.
A HTTPS egyelőre a Traefik alapértelmezett önaláírt tanúsítványát használja;
ez önmagában nem lesz megbízható a böngészők és Actions konténerek számára.
Publikus használat előtt DNS, megbízható TLS és a helyi hozzáférési korlátozás
tudatos módosítása szükséges. A runner regisztrációs példájában lévő belső HTTP-cím
nem oldja meg a HTTPS repository URL-ek tanúsítvány- és névfeloldási követelményeit.

Hivatalos dokumentáció: [Forgejo Docker](https://forgejo.org/docs/latest/admin/installation/docker/),
[runner Docker](https://forgejo.org/docs/latest/admin/actions/installation/docker/),
[runner konfiguráció](https://forgejo.org/docs/latest/admin/actions/configuration/).
