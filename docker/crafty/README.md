# Crafty, Minecraft-router és PostgreSQL

A `docker-compose.yml` a `10.1.1.3` Minecraft VM-en futó szolgáltatásokat írja le.
A telepítést a [Minecraft Terraform-modul](../../terraform/mc/README.md) végzi.

| Szolgáltatás | Funkció / hostport |
| --- | --- |
| `crafty` | Crafty HTTPS `8443`, Dynmap `8123`, Bedrock UDP `19132` |
| `mc-router` | Java Minecraft TCP `25565`, hostname-alapú továbbítás |
| `database` | PostgreSQL 17, TCP `5432` |

A router `dori.mc.chililime.hu` esetén `crafty:25568`, `sch.mc.chililime.hu` esetén
`crafty:25565` címre továbbít. A Craftyban ezeknek a szervereknek külön futniuk kell.
A `USE_PROXY_PROTOCOL=true` miatt a router elé küldött proxy protokollját is egyeztetni kell;
a repository Traefik TCP-service-ében jelenleg nincs explicit PROXY-protokoll-kimenet.
Ez a Minecraft-forgalom külön ellenőrzendő előfeltétele.

## Előkészítés

A Crafty adatkönyvtárai `/home/mc/crafty/{backups,logs,servers,config,import}` alatt vannak.
A PostgreSQL adatkönyvtára a Compose mellett lévő `db-data/`.
A telepítő a helyi, Gitből kizárt `src/crafty.zip` archívumot várja; annak kibontása után
a `/home/mc/crafty/` könyvtárnak kell létrejönnie.

A VM-re külön `.env` kell a Compose mellé: `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`.
A jelenlegi Minecraft Terraform-modul nem másolja fel ezt a fájlt; ezért a PostgreSQL-es
stack teljes telepítéséhez ezt külön elő kell készíteni. Példa: [.env.template](.env.template).
A PostgreSQL jelszóváltozója csak új adatkönyvtár inicializálásakor állítja be a jelszót.
A `5432` hostport ki van publikálva: elérését a saját hálózati szabályaid szerint korlátozd.

Indítás nélküli Compose-ellenőrzés a repository gyökeréből:

```sh
docker compose --env-file docker/crafty/.env -f docker/crafty/docker-compose.yml config --quiet
```

A fenti validáció nem indít játék-, adatbázis- vagy Crafty-szolgáltatást.
