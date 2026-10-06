# Loadbalancer tűzfal

A `firewall.yml` telepíti és bekapcsolja az UFW-t. Bejövő forgalom alapból tiltott,
kimenő forgalom engedélyezett. TCP `22`, `80`, `443` engedélyezett,
a TCP `9100/9101` kizárólag a `10.1.1.4` monitoring VM számára érhető el.

A playbook jelenleg nem engedi a Minecraft `25565` portját; ha ezen a tűzfalon kell
áthaladnia a játékforgalomnak, ezt külön hozzá kell adni a szabályokhoz.
A playbook nem telepít Traefiket és nem indít monitoringkonténert.
Az alkalmazás előtt az inventoryt és az SSH-hozzáférést ellenőrizd.
