#!/usr/bin/env bash
set -euo pipefail

# Only the dedicated disk with the serial configured in Terraform may be used.
target=/srv/forgejo
udevadm settle
mapfile -t disks < <(lsblk -dnpo NAME,SERIAL | awk '$2 == "forgejo-data" { print $1 }')
[[ "${#disks[@]}" -eq 1 ]] || { echo "Expected exactly one forgejo-data disk" >&2; exit 1; }
disk=${disks[0]}
[[ -b "$disk" ]] || { echo "Missing Forgejo data disk: $disk" >&2; exit 1; }

if [[ -z "$(blkid -s TYPE -o value "$disk" || true)" ]]; then
  # Refuse partitioned disks and any existing signature; never force-format.
  [[ "$(lsblk -nr -o NAME "$disk" | wc -l)" -eq 1 ]]
  [[ -z "$(wipefs --no-act --noheadings --output TYPE "$disk")" ]]
  [[ -z "$(lsblk -nr -o MOUNTPOINTS "$disk" | tr -d '[:space:]')" ]]
  mkfs.ext4 -L forgejo-data "$disk"
fi
[[ "$(blkid -s TYPE -o value "$disk")" == ext4 ]]
uuid=$(blkid -s UUID -o value "$disk")
install -d -m 0755 "$target"
entry="UUID=$uuid $target ext4 defaults 0 2"
if ! grep -Fxq "$entry" /etc/fstab; then
  if awk '$1 !~ /^#/ && $2 == "/srv/forgejo" { found=1 } END { exit !found }' /etc/fstab; then
    echo "Conflicting /srv/forgejo entry in /etc/fstab" >&2
    exit 1
  fi
  printf '%s\n' "$entry" >> /etc/fstab
fi
if ! mountpoint -q "$target"; then
  # Do not hide data accidentally written on the OS disk.
  [[ -z "$(find "$target" -mindepth 1 -maxdepth 1 -print -quit)" ]]
  mount "$target"
fi
[[ "$(findmnt -n -o UUID --target "$target")" == "$uuid" ]]
install -d -o 1000 -g 1000 -m 0750 "$target/data"

# Docker must wait for the data disk on every boot, including automatic restarts.
install -d -m 0755 /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/docker.service.d/forgejo-storage.conf <<'EOF'
[Unit]
RequiresMountsFor=/srv/forgejo
EOF
systemctl daemon-reload
