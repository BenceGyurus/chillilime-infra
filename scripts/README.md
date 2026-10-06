# Telepítőscriptek

- `docker.sh`: Debian Docker APT repository, Docker Engine, Buildx és Compose plugin telepítése.
  Ütköző csomagok eltávolításával és csomagtelepítéssel jár.
- `traefik.sh`: legfrissebb GitHub-release letöltése architektúra szerint, rendszerfelhasználó,
  konfigurációjogosultságok, ACME-tároló és systemd unit előkészítése; elindítja/újraindítja Traefiket.

Ezek nem ellenőrzőprogramok: futtatásuk módosítja a gépet. A Terraform a megfelelő gépen futtatja őket.
Debian, root vagy megfelelő sudo, internet és működő APT szükséges. A Traefik script kezeli az
amd64, arm64 és armv7 architektúrát; meglévő statikus konfigurációt megtart.
A repository Traefik-konfigurációját a Terraform a script előtt telepíti.

Szintaktikai ellenőrzés futtatás nélkül, a repository gyökeréből:

```sh
bash -n scripts/docker.sh scripts/traefik.sh
```

A `latest`/legfrissebb release használata miatt különböző időpontok telepítései eltérő verziókat hozhatnak.
