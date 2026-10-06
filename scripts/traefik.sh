#!/usr/bin/env bash
set -euo pipefail

# 1. Root jogosultság ellenőrzése
if [ "$EUID" -ne 0 ]; then
  echo "Hiba: A scriptet rootként (vagy sudo-val) kell futtatni!" >&2
  exit 1
fi

echo "=== Traefik telepítő script indítása ==="

# 2. Függőségek telepítése friss csomaglistából
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ca-certificates curl tar

# 3. Architektúra detektálása
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  TRAEFIK_ARCH="amd64" ;;
  aarch64) TRAEFIK_ARCH="arm64" ;;
  armv7l)  TRAEFIK_ARCH="armv7" ;;
  *)
    echo "Nem támogatott architektúra: $ARCH" >&2
    exit 1
    ;;
esac

# 4. Legfrissebb Traefik verzió lekérdezése a GitHub API-ról
echo "Legfrissebb verzió lekérése a GitHubról..."
LATEST_TAG=$(curl --fail --silent --show-error --location --retry 3 "https://api.github.com/repos/traefik/traefik/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_TAG" ]; then
  echo "Nem sikerült lekérni a verziót a GitHub API-ról. Próbáljuk manuálisan vagy ellenőrizd a kapcsolatot." >&2
  exit 1
fi

echo "Kiválasztott verzió: $LATEST_TAG ($TRAEFIK_ARCH)"
DOWNLOAD_URL="https://github.com/traefik/traefik/releases/download/${LATEST_TAG}/traefik_${LATEST_TAG}_linux_${TRAEFIK_ARCH}.tar.gz"

# 5. Letöltés és kicsomagolás ideiglenes könyvtárba
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Letöltés innen: $DOWNLOAD_URL ..."
curl --fail --silent --show-error --location --retry 3 "$DOWNLOAD_URL" -o "$TMP_DIR/traefik.tar.gz"

tar -zxvf "$TMP_DIR/traefik.tar.gz" -C "$TMP_DIR" traefik
install -m 755 "$TMP_DIR/traefik" /usr/local/bin/traefik

# 6. Rendszerfelhasználó és csoport létrehozása (ha még nem létezik)
if ! id -u traefik >/dev/null 2>&1; then
  echo "Rendszerszintű 'traefik' felhasználó és csoport létrehozása..."
  getent group traefik >/dev/null || groupadd --system traefik
  useradd --system -g traefik --no-create-home --shell /bin/false traefik
fi

# Az alacsony portokhoz szükséges capability-t a systemd unit adja meg.

# 7. Konfigurációs könyvtárak és alap fájlok
mkdir -p /etc/traefik/conf.d

if [ ! -f /etc/traefik/traefik.yml ]; then
  echo "Alapértelmezett /etc/traefik/traefik.yml létrehozása..."
  cat <<'EOF' > /etc/traefik/traefik.yml
entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"

providers:
  file:
    directory: "/etc/traefik/conf.d"
    watch: true

api:
  dashboard: true
  insecure: true

log:
  level: INFO
EOF
fi

# Jogosultságok beállítása
chown -R root:traefik /etc/traefik
chmod 750 /etc/traefik
chmod 640 /etc/traefik/traefik.yml
# ACME storage must be writable by the service user before the first start.
touch /etc/traefik/acme.json
chown traefik:traefik /etc/traefik/acme.json
chmod 600 /etc/traefik/acme.json

# 8. Systemd service egység létrehozása
echo "Systemd service fájl létrehozása (/etc/systemd/system/traefik.service)..."
cat <<'EOF' > /etc/systemd/system/traefik.service
[Unit]
Description=Traefik Loadbalancer
Documentation=https://doc.traefik.io/traefik/
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
User=traefik
Group=traefik
ExecStart=/usr/local/bin/traefik --configFile=/etc/traefik/traefik.yml
Restart=on-failure
RestartSec=10s
LimitNOFILE=65536

# Biztonsági hardening
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ReadWritePaths=/etc/traefik/acme.json
ProtectHome=true

[Install]
WantedBy=multi-user.target
EOF

# 9. Service regisztrálása és indítása
echo "Systemd újratöltése és Traefik indítása..."
systemctl daemon-reload
systemctl enable traefik
systemctl restart traefik

echo ""
echo "=== Telepítés sikeresen befejeződött! ==="
systemctl status traefik --no-pager
