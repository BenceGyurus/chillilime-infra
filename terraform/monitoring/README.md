# Monitoring VM

A modul 103-as VM-et klónoz a `chililime` node 100-as template-jéből:
1 CPU, 2 GiB RAM, 20 GiB `vm-disk1` lemez, `vmbr1`, `10.1.1.4/24`, gateway `10.1.1.1`.
A cloud-init SSH-kulcsot telepít, a provisioner címe a VM konfigurációjából származik.

A helyi `.env` az [.env.template](.env.template) alapján készíthető.
A Proxmox- és VM-változók mellett szükséges a `../../docker/monitoring/.env`
és a `../../config/prometheus/pve.yml`. A Terraform ezek létezését a hash-ekhez is igényli.
A SSH-felhasználónak jelszó nélküli sudo szükséges.

A telepítő `/home/monitoring/` alatt készíti elő a fájlokat, telepíti a Dockert és a node-exportert,
majd validálja és elindítja a Compose-stacket. A konfigurációk hash-e és a VM-életciklus
követi a szükséges újratelepítést; a konténerek újralétrehozása nem törli a named volume-okat.

Részletes előfeltételek, adatok és riasztások: [monitoring](../../docker/monitoring/README.md).
Általános Terraform-használat: [terraform](../README.md).
