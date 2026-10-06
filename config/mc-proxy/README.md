# Minecraft-proxy minták

A `config.yml` BungeeCord-kompatibilis, a `velocity.toml` Velocity konfigurációminta.
A Crafty Compose jelenleg `itzg/mc-router` szolgáltatást használ; egyik minta sincs hozzá mountolva,
és a Terraform sem telepíti ezeket proxyként.

Mindkét mintában `crafty:25565` és `crafty:25568` backend szerepel, a proxy portja `25577`.
Ezek a Docker-hálózati nevek csak azonos hálózaton működnek.
Az offline-mode és a továbbított játékosazonosítók miatt a backend hozzáférését és a proxy
hitelesítési modelljét használat előtt külön kell beállítani.

A Velocity `forwarding-secret-file` által hivatkozott fájl hitelesítési titok,
nem commitolható. A `${CFG_MOTD}` helyettesítése csak megfelelő konfiguráció-előkészítővel működik;
a TOML önmagában nem végez környezetiváltozó-helyettesítést.
