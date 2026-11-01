# Forgejo

Forgejo `16.0.5`, SQLite-tal, engedélyezett Actions-szel. A `/data` bind mount
a `/srv/forgejo/data` könyvtárat használja az 50 GiB-os `storage-mirror` adatlemezen.
HTTP: 3000, Git SSH: 2222. A konténerlogok rotáltak.

A Terraform `/opt/forgejo` alá telepíti a Compose fájlt és a domain/URL override-ot.
Másolja a helyi `.env` fájlt is, 0600 jogosultsággal, és explicit `--env-file`
kapcsolóval használja. A `.env` változása új provisionálást kér.
A `FORGEJO_DOMAIN` és `FORGEJO_ROOT_URL` értékei elsőbbséget kapnak a Terraform
domain/URL változóival szemben; hiányzó vagy üres értéknél azok az alapértékek.
Az `.env.template` alapján készíthető saját `.env`; a valódi fájlt ne commitold.
Kézi futtatás előtt az adatlemezt és a Docker mount-függőségét is elő kell készíteni.

Telepítés, mentés és runner: [Terraform modul](../../terraform/forgejo/README.md).
