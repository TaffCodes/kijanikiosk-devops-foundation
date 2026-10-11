# KijaniKiosk Access Model Design

| Directory / File | Owner | Group | Mode | Additional ACLs | Reasoning |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `/opt/kijanikiosk/api/` | `kk-api` | `kk-api` | `750` | `amina: r-x` | Strict isolation. Only the API service can write here. Amina needs read/execute for operational troubleshooting. |
| `/opt/kijanikiosk/payments/` | `kk-payments` | `kk-payments` | `750` | `amina: r-x` | Strict isolation to protect payment processing logic. |
| `/opt/kijanikiosk/config/` | `root` | `kijanikiosk` | `640` (files) / `750` (dir) | `amina: r--` | Owned by root to prevent service accounts from altering configs. Group read allows all services to access DB/API keys. |
| `/opt/kijanikiosk/shared/logs/` | `kk-logs` | `kk-logs` | `2770` (SGID) | `kk-api: rwx`, `kk-payments: r-x`, `amina: r-x` | SGID ensures all new logs belong to the `kk-logs` group. ACLs handle the complex multi-user access (API writes, others read) that standard chmod cannot support. |
| `/opt/kijanikiosk/scripts/deploy.sh` | `root` | `root` | `750` | None | Stripped the SUID bit and world-write permissions to close a critical privilege escalation vector. |
