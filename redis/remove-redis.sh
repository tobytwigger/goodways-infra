#!/usr/bin/env bash
# uninstall-redis.sh
# Removes Redis 7 and redis_exporter.
# Pass --purge-data to also delete /var/lib/redis.
#
# Usage: sudo ./uninstall-redis.sh [--purge-data]

set -euo pipefail

PURGE_DATA=false
[[ "${1:-}" == "--purge-data" ]] && PURGE_DATA=true

log() { echo ""; echo "==> $*"; }
ok()  { echo "    [ok]   $*"; }

[[ $EUID -ne 0 ]] && { echo "ERROR: Run with sudo." >&2; exit 1; }

log "Removing redis_exporter"
systemctl stop redis_exporter    2>/dev/null || true
systemctl disable redis_exporter 2>/dev/null || true
rm -f /etc/systemd/system/redis_exporter.service /etc/default/redis_exporter
rm -f /usr/local/bin/redis_exporter
userdel redis_exporter 2>/dev/null || true
systemctl daemon-reload
ok "redis_exporter removed."

log "Removing Redis"
systemctl stop redis-server    2>/dev/null || true
systemctl disable redis-server 2>/dev/null || true
apt-get remove -y redis-server redis-tools 2>/dev/null || true
apt-get autoremove -y 2>/dev/null || true

if $PURGE_DATA; then
  rm -rf /var/lib/redis
  ok "Redis data directory removed."
fi

ok "Redis removed."
echo ""
$PURGE_DATA && echo "Done. All data removed." || echo "Done. Data preserved. Pass --purge-data to also remove /var/lib/redis."