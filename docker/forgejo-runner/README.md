# Forgejo Actions runner

A `turiloki-org-debian` szervezetszintű runner a `Turiloki` szervezet engedélyezett
repóinak jobjait fogadja, repo-nként külön regisztráció nélkül. A Debian VM
10 CPU-val, 16 GiB RAM-mal és 80 GiB rendszerlemezzel fut. A digesttel rögzített
Forgejo runner verziója 13.2.0. Kapacitása összesen **6 job**, minden repóra és
PR-ra együtt; ez nem repónként hat hely.

Címkék: `debian` → `turiloki-ci:node22-bookworm-v1`, `debian-android` →
`turiloki-android:node22-sdk36-v1`. Mindkét label ugyanazt a hat helyet használja.
A job image-eket a TuriLoki repó CI Dockerfile-jaiból kell felépíteni.
Az egymástól független jobok és PR-ok párhuzamosan futhatnak. A `needs` függőségek
és az azonos `concurrency.group` szándékosan sorba állíthatják vagy törölhetik őket.

A regisztráció titkos adatai a host `/opt/forgejo-runner/config.yml`
`server.connections` részében vannak, 0600 jogosultsággal; Terraform nem tárolja
ezeket. A régi `.runner` regisztrációt a konfigurációkezelő szintén támogatja.
A cache szolgáltatás ki van kapcsolva. A runner saját VM-je Docker socketjéhez
root hozzáférést kap, és KVM-et ad az Android joboknak. A konténerek alapból nem
privileged módban futnak. Ez közös bizalmi kör: különösen nem megbízható forkokhoz
vagy publikálási titkok elkülönítéséhez külön runner VM/pool szükséges.

## Karbantartás

A maximális jobidő, a runner `shutdown_timeout` és a Compose `stop_grace_period`
6 óra. A leállítás így megvárhatja a futó jobokat. Új feladatok felvételének
szüneteltetéséhez, majd a futó jobok befejezésének megvárásához a VM-en:

```sh
sudo python3 /opt/forgejo-runner/drain.py
sudo docker compose -f /opt/forgejo-runner/docker-compose.yml up -d --force-recreate
```

A drain átmenetileg `maintenance-draining` szerveroldali labelt állít be.
Siker után a daemon újraindítása állítja vissza a szokásos címkéket. Megszakítás
vagy timeout esetén a script visszaállítja őket; kézi helyreállítás:
`sudo python3 /opt/forgejo-runner/drain.py --restore`.

## Napi takarítás

A `forgejo-runner-cleanup.timer` budapesti idő szerint 03:00–03:15 között fut.
A 7 napnál régebbi dangling image-eket és nem használt build cache-t takarítja.
A címkézett CI image-eket, volume-okat, konténereket és regisztrációs adatokat
megtartja. Ha a runneren kívül bármilyen konténer fut, kihagyja a takarítást.
Kikapcsolt gép esetén a systemd indulás után pótolja a kimaradt időzítést.

```sh
systemctl list-timers forgejo-runner-cleanup.timer
/usr/local/sbin/forgejo-runner-cleanup --dry-run
journalctl -u forgejo-runner-cleanup.service
```

## Kapacitáspróba (2026-10-07)

A 10 CPU / 16 GiB VM-en a kézzel indított Forgejo matrix minden jobja 2 GiB RAM-ot
foglalt és egy CPU-szálat terhelt 90 másodpercig. Mindhárom, majd mind a négy job
valóban átfedve futott és sikeresen befejeződött; `oom_kill=0`, daemon restart=0.
A háromjobos mintánál kb. 9,2 GiB, a négyjobosnál kb. 7 GiB elérhető RAM maradt.
Ez szintetikus mérés: négy Android-emulátort vagy négy nagy buildet nem igazol.

A kézi kapacitáspróba a CI repó külön diagnosztikai ágán található. Konkrét
privát hostnevek, címek, hozzáférési adatok és regisztrációs titkok ebbe az
útmutatóba nem kerülhetnek.

A későbbi hatjobos próba szintén sikeres: hat, egyenként 2 GiB RAM-ot és egy CPU-t
terhelő job közel 89 másodpercig egyszerre futott. A mintákban legalább 2,4 GiB
elérhető RAM maradt, OOM nélkül. Az élő kapacitás ezután hatra állt. Ez továbbra
sem jelent hat egyidejű nagy Android-buildre vonatkozó garanciát.
