#!/bin/bash
# KijaniKiosk Production Provisioning Script
# Expected dirty conditions found in pre-provisioning audit:
# - Service accounts (kk-api, kk-payments, kk-logs) already exist: handled in Phase 2 via id checks
# - /opt/kijanikiosk directories exist with partial ACLs: handled in Phase 3 via setfacl overwrites
# - ufw has leftover deny rules from Thursday: handled in Phase 5 via ufw reset
# - Packages are already installed/held: handled in Phase 1 via version detection
# - systemd units exist from Wednesday: handled in Phase 4 via heredoc overwrites
# - Log accumulation and missing logrotate config: handled in Phase 6

set -euo pipefail

readonly NODE_MAJOR_VERSION="20"
readonly APP_GROUP="kijanikiosk"
readonly APP_BASE="/opt/kijanikiosk"
readonly NGINX_VERSION=$(apt-cache policy nginx 2>/dev/null | grep Candidate | awk '{print $2}')

log() { echo "[$(date +%FT%T)] INFO: $*"; }
success() { echo "[$(date +%FT%T)] OK: $*"; }
error() { echo "[$(date +%FT%T)] ERROR: $*" >&2; exit 1; }

[[ $EUID -ne 0 ]] && error "Must run as root"

provision_packages() {
    log "=== Phase 1: Package Installation ==="
    
    if dpkg -l | grep -q nginx && apt-mark showhold | grep -q nginx; then
        log "Packages already installed and held. Skipping re-installation."
    else
        apt-get update -qq
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl gnupg acl ufw
        
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor --yes -o /usr/share/keyrings/nodesource.gpg
        echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR_VERSION}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list
        
        apt-get update -qq
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "nginx=${NGINX_VERSION}" nodejs
        
        apt-mark hold nginx nodejs >/dev/null
    fi
    success "Packages installed and pinned"
}

provision_users() {
    log "=== Phase 2: Service Accounts ==="
    getent group "${APP_GROUP}" >/dev/null || groupadd --system "${APP_GROUP}"
    
    for svc in kk-api kk-payments kk-logs; do
        if id "$svc" &>/dev/null; then
            log "Already exists: $svc"
        else
            useradd --system --no-create-home --shell /usr/sbin/nologin "$svc"
        fi
        usermod -aG "${APP_GROUP}" "$svc"
    done
    success "Service accounts validated"
}

provision_dirs() {
    log "=== Phase 3: Directory Structure ==="
    mkdir -p "${APP_BASE}"/{api,payments,logs,config,scripts,shared/logs,health}
    
    touch "${APP_BASE}/config/db.env" "${APP_BASE}/config/payments-api.env"
    
    chown -R kk-api:kk-api "${APP_BASE}/api"
    chown -R kk-payments:kk-payments "${APP_BASE}/payments"
    chown -R kk-logs:kk-logs "${APP_BASE}/logs"
    chown -R root:"${APP_GROUP}" "${APP_BASE}/config"
    chown -R kk-logs:kk-logs "${APP_BASE}/shared/logs"
    
    chown -R root:"${APP_GROUP}" "${APP_BASE}/health"
    chmod 750 "${APP_BASE}/health"
    
    chmod 750 "${APP_BASE}/api" "${APP_BASE}/payments" "${APP_BASE}/logs" "${APP_BASE}/config"
    chmod 640 "${APP_BASE}/config/"*.env
    chmod 2770 "${APP_BASE}/shared/logs"
    
    setfacl -R -m u:kk-api:rwx -m u:kk-payments:r-x "${APP_BASE}/shared/logs"
    setfacl -d -m u:kk-api:rwx -m u:kk-payments:r-x "${APP_BASE}/shared/logs"
    success "Directory structure and ACLs established"
}

provision_services() {
    log "=== Phase 4: systemd Unit Files ==="
    
    # kk-logs.service (Hardened < 3.5)
    cat << 'UNIT' > /etc/systemd/system/kk-logs.service
[Unit]
Description=KijaniKiosk Log Aggregator

[Service]
Type=simple
User=kk-logs
Group=kk-logs
ExecStart=/usr/bin/node /opt/kijanikiosk/logs/server.js
ExecReload=/bin/kill -HUP $MAINPID
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
CapabilityBoundingSet=
MemoryDenyWriteExecute=true
LockPersonality=true
RestrictNamespaces=true
RestrictRealtime=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictSUIDSGID=true
PrivateDevices=true
SystemCallArchitectures=native
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
[Install]
WantedBy=multi-user.target
UNIT

    # kk-api.service (Hardened < 3.5)
    cat << 'UNIT' > /etc/systemd/system/kk-api.service
[Unit]
Description=KijaniKiosk API Service
After=network-online.target
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
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=/opt/kijanikiosk/shared/logs
ProtectHome=true
CapabilityBoundingSet=
MemoryDenyWriteExecute=true
LockPersonality=true
RestrictNamespaces=true
RestrictRealtime=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictSUIDSGID=true
PrivateDevices=true
SystemCallArchitectures=native
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
[Install]
WantedBy=multi-user.target
UNIT

    # kk-payments.service (Extreme Hardening < 2.5)
    cat << 'UNIT' > /etc/systemd/system/kk-payments.service
[Unit]
Description=KijaniKiosk Payments Service
After=network-online.target kk-api.service
Wants=network-online.target kk-api.service

[Service]
Type=simple
User=kk-payments
Group=kk-payments
WorkingDirectory=/opt/kijanikiosk/payments
ExecStart=/usr/bin/node /opt/kijanikiosk/payments/server.js
Restart=on-failure
RestartSec=5s
EnvironmentFile=/opt/kijanikiosk/config/payments-api.env
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=/opt/kijanikiosk/shared/logs
ProtectHome=true
CapabilityBoundingSet=
MemoryDenyWriteExecute=true
LockPersonality=true
RestrictNamespaces=true
RestrictRealtime=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
SystemCallFilter=@system-service
SystemCallArchitectures=native
RestrictSUIDSGID=true
PrivateDevices=true
[Install]
WantedBy=multi-user.target
UNIT

    systemctl daemon-reload
    systemctl enable kk-api.service kk-payments.service kk-logs.service
    success "systemd units deployed and enabled"
}

provision_firewall() {
    log "=== Phase 5: Firewall Configuration ==="
    ufw --force reset >/dev/null
    ufw default deny incoming >/dev/null
    ufw default allow outgoing >/dev/null
    
    ufw allow 22/tcp comment 'SSH Access' >/dev/null
    ufw allow 80/tcp comment 'HTTP Access' >/dev/null
    ufw allow from 127.0.0.1 to any port 3001 comment 'Nginx proxy loopback' >/dev/null
    ufw allow from 10.0.1.0/24 to any port 3001 comment 'Monitoring health checks' >/dev/null
    ufw deny 3001/tcp comment 'Block external direct port 3001 access' >/dev/null
    
    ufw --force enable >/dev/null
    success "Firewall reset and intent-based rules applied"
}

provision_logging() {
    log "=== Phase 6: Journal Persistence & Log Rotation ==="
    mkdir -p /var/log/journal
    systemd-tmpfiles --create --prefix /var/log/journal
    
    mkdir -p /etc/systemd/journald.conf.d/
    cat > /etc/systemd/journald.conf.d/kijanikiosk.conf << 'CONF'
[Journal]
Storage=persistent
Compress=yes
SystemMaxUse=500M
SystemMaxFileSize=50M
CONF
    systemctl restart systemd-journald

    cat > /etc/logrotate.d/kijanikiosk << 'LOGROTATE'
/opt/kijanikiosk/shared/logs/*.log {
    daily
    su kk-logs kk-logs
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 640 kk-logs kijanikiosk
    sharedscripts
    postrotate
        systemctl reload kk-logs.service 2>/dev/null || true
    endscript
}
LOGROTATE
    
    logrotate --debug /etc/logrotate.d/kijanikiosk >/dev/null 2>&1 || error "Logrotate config invalid"
    success "Logging persistence and daily rotation configured"
}

provision_health() {
    log "=== Phase 7: Monitoring Health Checks ==="
    api_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3000" 2>/dev/null && echo '"ok"' || echo '"down"')
    payments_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3001" 2>/dev/null && echo '"ok"' || echo '"down"')
    
    printf '{"timestamp":"%s", "kk-api":%s, "kk-payments":%s}\n' \
    "$(date -Is)" "$api_status" "$payments_status" > /opt/kijanikiosk/health/last-provision.json
    
    chown kk-logs:kijanikiosk /opt/kijanikiosk/health/last-provision.json
    chmod 640 /opt/kijanikiosk/health/last-provision.json
    success "Health check JSON written to /opt/kijanikiosk/health/last-provision.json"
}

verify_state() {
    log "=== Phase 8: Final Verification ==="
    local failed=0

    for svc in kk-api kk-payments kk-logs; do
        id "$svc" >/dev/null 2>&1 || { log "FAIL: User $svc missing"; ((failed++)); }
    done

    apt-mark showhold | grep -q nginx || { log "FAIL: nginx not held"; ((failed++)); }

    systemctl is-enabled kk-payments.service >/dev/null 2>&1 || { log "FAIL: kk-payments not enabled"; ((failed++)); }

    local fw_status
    fw_status=$(sudo ufw status)
    echo "$fw_status" | grep -q "22/tcp.*ALLOW" && success "PASS: SSH allowed" || { log "FAIL: SSH missing"; ((failed++)); }
    echo "$fw_status" | grep -q "80/tcp.*ALLOW" && success "PASS: HTTP allowed" || { log "FAIL: HTTP missing"; ((failed++)); }
    echo "$fw_status" | grep -q "3001/tcp.*DENY" && success "PASS: Port 3001 external deny present" || { log "FAIL: 3001 deny missing"; ((failed++)); }

    [[ -f /opt/kijanikiosk/health/last-provision.json ]] || { log "FAIL: Health check file missing"; ((failed++)); }

    if [[ $failed -eq 0 ]]; then
        success "All validation checks passed. Server is clean."
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
    provision_logging
    provision_health
    verify_state
}

main "$@"
