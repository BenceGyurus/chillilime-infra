# Inventory

A `production.ini` a loadbalancer `10.1.1.254` címét és az `ansible_user=root` beállítást tartalmazza.
Ez inventoryfájl, nem host-változók automatikusan felismert YAML könyvtára;
a playbookhoz `-i host_vars/production.ini` argumentummal add meg.

Az IP és az SSH-felhasználó jelenleg Gitben van. Jelszót vagy privát SSH-kulcsot ide ne írj;
használj helyi SSH-kulcsot vagy külön, nem commitolt titokkezelést.
