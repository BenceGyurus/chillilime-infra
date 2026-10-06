# Terraform-modulok

| Modul | Feladat |
| --- | --- |
| [mc](mc/README.md) | Minecraft VM, Crafty Docker-stack és node-exporter |
| [monitoring](monitoring/README.md) | monitoring VM, konfigurációk és Docker-stack |
| [loadbalancer](loadbalancer/README.md) | Debian LXC, Traefik és node-exporter |
| [router](router/README.md) | egy OPNsense VLAN-erőforrás, még hiányos modul |

A könyvtárak önálló root modulok, külön local state-tel. A Proxmox-modulok
`bpg/proxmox` és `hashicorp/null` providert használnak. A provider-hitelesítés
`TF_VAR_*` környezeti változókból adható meg; a `.env` fájlokat a Terraform nem olvassa be magától.

Példa egy modul könyvtárában, saját helyi `.env` létrehozása után:

```sh
set -a
source .env
set +a
terraform init
terraform validate
terraform plan
```

Az `init` providereket tölt le, a `validate` a konfigurációt ellenőrzi,
a `plan` lekérdezheti a Proxmoxot, de erőforrást nem módosít. Az `apply` valódi telepítés.
A fájl- és remote-exec provisionerekhez helyi SSH-kulcs, távoli SSH és megfelelő sudo/root kell.

A `.terraform.lock.hcl` fájlokat commitold. A `.terraform/`, `.env`, `.tfvars`, state és plan
nem publikálható; state/plan érzékeny értékeket is tartalmazhat.
A provisionerek módosítását a hash/triggerek követik; egy új VM esetén a lifecycle is újratelepítést kér.
