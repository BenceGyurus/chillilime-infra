# Minecraft VM

A `main.tf` 101-es VM-et klónoz a `chililime` node 100-as template-jéből:
2 CPU, 8 GiB RAM, 30 GiB `vm-disk1` lemez, `vmbr1`, `10.1.1.3/24`, gateway `10.1.1.1`.
A cloud-init a helyi `~/.ssh/id_ed25519.pub` kulcsot adja meg;
a telepítő az ehhez tartozó privát kulccsal csatlakozik.

A helyi `.env` az [.env.template](.env.template) alapján készíthető.
Szükséges változók: `proxmox_host`, `proxmox_username`, `proxmox_password`, `vm_username`, `vm_password`.
A template-ben működő SSH és a provisionerek által igényelt root/sudo szükséges.

A Docker-provisioner felmásolja a telepítőt, a Crafty Compose fájlt és a Gitből kizárt
`../../src/crafty.zip` archívumot. A kibontás és a jogosultságok után elindítja a stacket.
Külön resource telepíti a node-exportert a Docker-telepítés után, így az APT-műveletek nem futnak egyszerre.
A Docker-stack PostgreSQL `.env` fájlját jelenleg külön kell a gépre tenni.
Részletek: [Crafty](../../docker/crafty/README.md).

A használat és a nem publikálható Terraform-fájlok listája a [közös leírásban](../README.md) található.
