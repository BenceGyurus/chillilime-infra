# Chillilime infrastruktúra

Proxmox-alapú otthoni infrastruktúra Terraform-modulokkal, Docker szolgáltatásokkal,
Traefik loadbalancerrel és Prometheus/Grafana monitoringgal.

## Felépítés

| Rész | Feladat | Leírás |
| --- | --- | --- |
| Terraform | VM-ek, LXC és szolgáltatások előkészítése | [terraform](terraform/README.md) |
| Docker | Crafty, Minecraft-router, PostgreSQL és monitoring | [docker](docker/README.md) |
| Konfigurációk | Traefik, Prometheus, Grafana, proxy minták | [config](config/README.md) |
| Ansible | Loadbalancer tűzfal | [ansbile](ansbile/README.md) |
| Scriptek | Docker és Traefik telepítők | [scripts](scripts/README.md) |
| `interfaces` | Proxmox bridge-ek és policy routing mintája | az alábbi hálózati rész |

A könyvtár neve jelenleg `ansbile`; a parancsokban is ezt használd.

## Hálózat

| Eszköz | Cím | Erőforrás |
| --- | --- | --- |
| OPNsense | `10.1.1.1` | átjáró és API |
| Proxmox | `10.1.1.2` | `chililime` node |
| Minecraft | `10.1.1.3` | 101-es VM |
| Monitoring | `10.1.1.4` | 103-as VM |
| Loadbalancer | `10.1.1.254` | Debian LXC |

A VM-ek a 100-as template-ből készülnek, a belső hálózat a `vmbr1` bridge-et használja.
Az `interfaces` fájl gépspecifikus példa, nem automatikus telepítő. A `vmbr1` címében
jelenleg `10.1.1.0/24` szerepel, ami ebben az alhálózatban hálózati cím; alkalmazás előtt
ellenőrizd a tényleges hostcímet, a gateway-t, a fizikai interfészeket és az útvonalakat.
Ne másold rá ellenőrzés nélkül egy működő gép hálózati konfigurációjára.

## Használat

A modulok külön Terraform-state-tel működnek. Először a template-et, bridge-eket,
tárolókat, SSH-hozzáférést és helyi titkokat kell előkészíteni. A pontos lépések a részek
README-jében szerepelnek. A router modul még nem teljes önálló telepítés.

A `terraform plan` infrastruktúrát nem módosít, de kapcsolatba léphet a Proxmox API-val.
A `terraform apply`, a telepítőscriptek, az Ansible playbook és a `docker compose up`
valódi módosításokat végeznek, szolgáltatásokat indíthatnak vagy újraindíthatnak.

## Mi kerülhet GitHubra?

Verziókezelésbe kerülhet a forráskód, a README, a titok nélküli konfiguráció,
az üres `.env.template`/`.env.example` és a Terraform `.terraform.lock.hcl` fájlja.
A lock fájl a provider verzióit és ellenőrzőösszegeit rögzíti; nem Terraform-state.

A `.gitignore` kizárja a valódi `.env` fájlokat és változataikat, a PVE-hitelesítést,
Terraform-state-et és planeket, provider-cache-t, privát kulcsokat, tanúsítványkulcsokat,
ACME-tárolót, proxy forwarding secretet, helyi adatkönyvtárakat, logokat és a `src/` tartalmát.
A `src/crafty.zip` helyi előfeltétel, nem publikálandó szervermentés.

A konfigurációkban lévő belső IP-k, domainek, ACME e-mail és az Ansible inventory
jelenleg publikálható fájlok részei: nem hitelesítési titkok, de feltárják az infrastruktúra
felépítését. Nyilvános repository előtt ezt vedd figyelembe.

Commit előtt ellenőrizd a tényleges staged tartalmat:

```sh
git status --short --ignored
git diff --cached --name-status
git diff --cached
```

A `.gitignore` nem távolít el korábban commitolt adatot és `git add -f`-fel megkerülhető.
Ne commitolj hitelesítési adatot; ha korábban titok került Gitbe, a titok cseréje is szükséges.
