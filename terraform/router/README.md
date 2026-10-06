# OPNsense VLAN-minta

A `main.tf` egy `opnsense_interfaces_vlan` erőforrást definiál:
`vtnet0` szülőinterfész, VLAN tag `10`, priority `0`, leírás `proxmox`.
A `variables.tf` jelenleg üres.

Ez még nem teljes, önálló Terraform-modul: nincs megadva provider source/verzió,
hitelesítés vagy provider-konfiguráció. A többi modulhoz hasonló `init/plan/apply`
folyamat itt még nincs előkészítve. Használat előtt ezeket és a tényleges interfésznevet
az alkalmazott OPNsense provider szerint ki kell alakítani.

A VLAN-erőforrás önmagában nem készít teljes LAN/WAN konfigurációt vagy tűzfalszabályokat.
API-kulcsot és jelszót ne írj a verziókezelt fájlba.
