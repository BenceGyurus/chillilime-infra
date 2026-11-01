#!/usr/bin/env bash
set -euo pipefail

dry_run=false
case "${1:-}" in
  --dry-run) dry_run=true ;;
  "") ;;
  *) echo "Usage: $0 [--dry-run]" >&2; exit 2 ;;
esac

# Never overlap two cleanup runs. Docker itself protects resources in use.
exec 9>/run/lock/forgejo-runner-cleanup.lock
flock -n 9 || exit 0

idle() {
  local running runner id
  running=$(docker ps -q)
  runner=$(docker ps -q \
    --filter label=com.docker.compose.project=forgejo-runner \
    --filter label=com.docker.compose.service=runner)
  for id in $running; do
    if ! grep -Fxq "$id" <<< "$runner"; then
      echo "Skipping cleanup: another container is running ($id)."
      return 1
    fi
  done
}

idle || exit 0
if "$dry_run"; then
  echo "Idle: would prune dangling images and unused build cache older than 168 hours."
  echo "Tagged images, containers, volumes and runner registration are preserved."
  docker system df
  exit 0
fi

echo "Pruning dangling images older than 168 hours (keeping all tagged CI images)."
docker image prune --force --filter until=168h
idle || exit 0
echo "Pruning unused build cache older than 168 hours."
docker builder prune --force --filter until=168h
docker system df
