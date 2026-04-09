#!/usr/bin/env bash
# bootstrap-redis.sh
# Installs and configures Redis 7 and redis_exporter on Ubuntu 24.04.
# Idempotent — safe to re-run.
#
# Usage: sudo ./bootstrap-redis.sh
# Repo:  goodways-infra

set -euo pipefail

# ─────────────────────────────────────────────────────────────
# CONFIGURATION — edit these before running
# ─────────────────────────────────────────────────────────────

REDIS_PASSWORD="changeme"
REDIS_MAX_MEMORY="256mb"

REDIS_EXPORTER_VERSION="1.62.0"

# ─────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────

log()  { echo ""; echo "==> $*"; }
skip() { echo "    [skip] $*"; }
ok()   { echo "    [ok]   $*"; }

require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Run this script with sudo." >&2
    exit 1
  fi
}

# ─────────────────────────────────────────────────────────────
# REDIS 7
# ─────────────────────────────────────────────────────────────

install_redis() {
  log "Redis 7"

  if systemctl is-active --quiet redis-server; then
    skip "Redis is already running."
  else
    apt-get install -y redis-server
    ok "Redis installed."
  fi

  cat > /etc/redis/redis.conf <<EOF
bind 127.0.0.1 -::1
port 6379
requirepass ${REDIS_PASSWORD}
maxmemory ${REDIS_MAX_MEMORY}
maxmemory-policy allkeys-lru
save 60 1
loglevel notice
daemonize no
supervised systemd
dir /var/lib/redis
logfile /var/log/redis/redis-server.log
EOF

  ok "Redis config written."
  systemctl enable redis-server
  systemctl restart redis-server
  ok "Redis started."
}

# ─────────────────────────────────────────────────────────────
# REDIS EXPORTER
# ─────────────────────────────────────────────────────────────

install_redis_exporter() {
  log "redis_exporter v${REDIS_EXPORTER_VERSION}"

  if [[ -f /usr/local/bin/redis_exporter ]]; then
    skip "redis_exporter binary already exists."
  else
    curl -fsSL "https://github.com/oliver006/redis_exporter/releases/download/v${REDIS_EXPORTER_VERSION}/redis_exporter-v${REDIS_EXPORTER_VERSION}.linux-amd64.tar.gz" \
      -o /tmp/redis_exporter.tar.gz

    tar -xzf /tmp/redis_exporter.tar.gz -C /tmp
    mv "/tmp/redis_exporter-v${REDIS_EXPORTER_VERSION}.linux-amd64/redis_exporter" /usr/local/bin/
    chmod +x /usr/local/bin/redis_exporter
    rm -rf /tmp/redis_exporter*
    ok "redis_exporter binary installed."
  fi

  id redis_exporter &>/dev/null || useradd --no-create-home --shell /bin/false redis_exporter

  cat > /etc/default/redis_exporter <<EOF
REDIS_ADDR=redis://127.0.0.1:6379
REDIS_PASSWORD=${REDIS_PASSWORD}
REDIS_EXPORTER_LOG_FORMAT=json
EOF
  chmod 600 /etc/default/redis_exporter

  cat > /etc/systemd/system/redis_exporter.service <<'EOF'
[Unit]
Description=Prometheus Redis Exporter
After=redis-server.service
Wants=redis-server.service

[Service]
User=redis_exporter
EnvironmentFile=/etc/default/redis_exporter
ExecStart=/usr/local/bin/redis_exporter --web.listen-address=127.0.0.1:9121
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable redis_exporter
  systemctl restart redis_exporter
  ok "redis_exporter running on :9121."
}

# ─────────────────────────────────────────────────────────────
# VERIFY
# ─────────────────────────────────────────────────────────────

verify() {
  log "Verification"
  local all_ok=true

  check() {
    local label=$1 cmd=$2
    if eval "$cmd" &>/dev/null; then
      ok "$label"
    else
      echo "    [FAIL] $label"
      all_ok=false
    fi
  }

  check "Redis responding"        "redis-cli -a '${REDIS_PASSWORD}' ping"
  check "redis_exporter metrics"  "curl -sf http://127.0.0.1:9121/metrics | grep -q 'redis_up 1'"

  echo ""
  if $all_ok; then
    echo "All checks passed. Set REDIS_HOST=127.0.0.1 in Coolify."
  else
    echo "One or more checks failed. Check: journalctl -u <service> -n 50"
    exit 1
  fi
}

# ─────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────

require_root
apt-get update -qq

install_redis
install_redis_exporter
verify