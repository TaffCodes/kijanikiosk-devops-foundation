#!/bin/bash
# KijaniKiosk Idempotent Provisioning Script
set -euo pipefail

readonly NODE_MAJOR_VERSION="20"
readonly APP_GROUP="kijanikiosk"
readonly APP_BASE="/opt/kijanikiosk"

# Dynamically fetch the current candidate version to pin it safely
readonly NGINX_VERSION=$(apt-cache policy nginx 2>/dev/null | grep Candidate | awk '{print $2}')

log() { echo "[$(date +%FT%T)] INFO: $*"; }
success() { echo "[$(date +%FT%T)] OK: $*"; }
error() { echo "[$(date +%FT%T)] ERROR: $*" >&2; exit 1; }

[[ $EUID -ne 0 ]] && error "Must run as root or with sudo"
grep -qi ubuntu /etc/os-release || error "Designed for Ubuntu only"
log "Starting KijaniKiosk provisioning..."

provision_packages() {
    log "=== Phase 1: Package Installation ==="
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl gnupg acl ufw
    
    # Idempotent GPG key overwrite and NodeSource Repo addition
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor --yes -o /usr/share/keyrings/nodesource.gpg
    echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR_VERSION}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list
    
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "nginx=${NGINX_VERSION}" nodejs
    
    # Hold packages to prevent drift
    apt-mark hold nginx nodejs >/dev/null
    success "Installed and pinned Nginx (${NGINX_VERSION}) and Node.js (${NODE_MAJOR_VERSION}.x)"
}

provision_users() {
    log "=== Phase 2: Service Accounts ==="
    getent group "${APP_GROUP}" >/dev/null || groupadd --system "${APP_GROUP}"
    
    for svc in kk-api kk-payments kk-logs; do
        id "$svc" &>/dev/null || useradd --system --no-create-home --shell /usr/sbin/nologin "$svc"
        usermod -aG "${APP_GROUP}" "$svc"
    done
    
    id amina &>/dev/null && usermod -aG "${APP_GROUP}" amina || true
    success "Service accounts and groups configured"
}

provision_dirs() {
    log "=== Phase 3: Directory Structure ==="
    mkdir -p "${APP_BASE}"/{api,payments,logs,config,scripts,shared/logs}
    
    # Create dummy config files so systemd EnvironmentFile doesn't crash on load
    touch "${APP_BASE}/config/db.env" "${APP_BASE}/config/payments-api.env"
    
    chown -R kk-api:kk-api "${APP_BASE}/api"
    chown -R kk-payments:kk-payments "${APP_BASE}/payments"
    chown -R kk-logs:kk-logs "${APP_BASE}/logs"
    chown -R root:"${APP_GROUP}" "${APP_BASE}/config"
    chown -R kk-logs:kk-logs "${APP_BASE}/shared/logs"
    
    chmod 750 "${APP_BASE}/api" "${APP_BASE}/payments" "${APP_BASE}/logs" "${APP_BASE}/config"
    chmod 640 "${APP_BASE}/config/"*.env 2>/dev/null || true
    chmod 2770 "${APP_BASE}/shared/logs"
    
    setfacl -m u:kk-api:rwx -m u:kk-payments:r-x "${APP_BASE}/shared/logs"
    setfacl -d -m u:kk-api:rwx -m u:kk-payments:r-x "${APP_BASE}/shared/logs"
    success "Directory ownership, permissions, and ACLs applied"
}

provision_services() {
    log "=== Phase 4: systemd Unit Files ==="
    cat << 'UNIT' > /etc/systemd/system/kk-api.service
[Unit]
Description=KijaniKiosk API Service
Documentation=https://github.com/kijanikiosk/api/blob/main/README.md
After=network-online.target kk-payments.service
Wants=network-online.target

[Service]
Type=simple
User=kk-api
Group=kk-api
WorkingDirectory=/opt/kijanikiosk/api
ExecStart=/usr/bin/node /opt/kijanikiosk/api/server.js
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5s
StartLimitBurst=3
StartLimitIntervalSec=60s

EnvironmentFile=/opt/kijanikiosk/config/db.env
EnvironmentFile=/opt/kijanikiosk/config/payments-api.env
Environment="NODE_ENV=production"
Environment="PORT=3000"

StandardOutput=journal
StandardError=journal
SyslogIdentifier=kk-api

# Hardening Directives
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=/opt/kijanikiosk/shared/logs
ProtectHome=true
CapabilityBoundingSet=
MemoryDenyWriteExecute=true
LockPersonality=true


[Install]
WantedBy=multi-user.target
UNIT

    systemctl daemon-reload
    systemctl enable kk-api.service
    success "systemd unit configured and enabled"
}

provision_firewall() {
    log "=== Phase 5: Firewall Configuration ==="
    ufw --force reset >/dev/null
    ufw default deny incoming >/dev/null
    ufw default allow outgoing >/dev/null
    ufw allow 22/tcp >/dev/null
    ufw allow 80/tcp >/dev/null
    ufw --force enable >/dev/null
    success "ufw configured: ports 22 and 80 open"
}

verify_state() {
    log "=== Phase 6: Post-Provisioning Verification ==="
    local failed=0

    for svc in kk-api kk-payments kk-logs; do
        id "$svc" >/dev/null 2>&1 || { log "FAIL: Account missing: $svc"; ((failed++)); }
    done

    [[ -d "${APP_BASE}/shared/logs" ]] || { log "FAIL: Shared logs directory missing"; ((failed++)); }
    
    if [[ -n $(find "${APP_BASE}" -perm /4000 -type f 2>/dev/null) ]]; then
        log "FAIL: SUID files detected in ${APP_BASE}"
        ((failed++))
    fi

    apt-mark showhold | grep -q nginx || { log "FAIL: nginx not held"; ((failed++)); }
    apt-mark showhold | grep -q nodejs || { log "FAIL: nodejs not held"; ((failed++)); }

    systemctl is-enabled kk-api.service >/dev/null 2>&1 || { log "FAIL: kk-api.service not enabled"; ((failed++)); }

    if [[ $failed -eq 0 ]]; then
        success "Provisioning complete. Server is in known state."
    else
        error "Verification failed with $failed errors."
    fi
}

main() {
    provision_packages
    provision_users
    provision_dirs
    provision_services
    provision_firewall
    verify_state
}

main "$@"
