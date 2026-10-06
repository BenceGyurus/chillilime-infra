# Loadbalancer LXC

A modul unprivileged Debian LXC-t hoz létre a `chililime` node-on:
2 CPU, 256 MiB RAM, 4 GiB `vm-disk1` lemez, `vmbr1`, `10.1.1.254/24`.
A `container_template` meglévő Proxmox template volume ID; az alapértékhez tartozó template-et előre fel kell tölteni.

A helyi `.env` a [.env.template](.env.template) alapján készíthető.
A `vm_username` értéke `root` kell legyen: a modul más SSH-felhasználót nem hoz létre.
A `denes_public_key` SSH public key, nem privát kulcs; az értéke helyi környezeti változóban marad.
A további változók a Proxmox-elérés és a VM-jelszó.

A provisioner felmásolja a Traefik-telepítőt, a statikus konfigurációt,
a Minecraft- és Grafana-route-okat. Telepíti/újraindítja Traefiket és telepíti a node-exportert.
A `config`, `mc_config`, `services` és `installer` hash-ek követik a fájlok módosítását.
A dashboard-route minta felmásolása nincs ebben a modulban.

A tűzfal külön [Ansible playbook](../../ansbile/loadbalancer/README.md).
A portok és TLS-előfeltételek a [Traefik leírásában](../../config/traefik/README.md) vannak.
A modul használata: [közös Terraform README](../README.md).
