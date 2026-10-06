# Ansible

A könyvtár neve `ansbile`. Jelenleg a loadbalancer UFW tűzfalának playbookját tartalmazza.
Az inventory a `host_vars/production.ini` fájlban van; a `host_vars` elnevezés ellenére ez INI inventory.

## Helyi előkészítés

```sh
cd ansbile
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
ansible-galaxy collection install community.general
```

A Python-függőségeket a `requirements.txt` rögzíti, az UFW modul a `community.general` collectionből jön.
A virtuális környezet nem kerül Gitbe. Az inventory root SSH-hozzáférést használ a `10.1.1.254` címhez.

Indítás/módosítás nélküli szintaktikai ellenőrzés:

```sh
ansible-playbook -i host_vars/production.ini loadbalancer/firewall.yml --syntax-check
```

A tényleges alkalmazás parancsa az előzőből a `--syntax-check` elhagyásával készül;
az a távoli tűzfalat módosítja. Részletek: [loadbalancer](loadbalancer/README.md),
[inventory](host_vars/README.md).
