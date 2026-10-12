# KijaniKiosk Final Access Model

## Core Directories (Standard Ownership)
| Directory | Owner:Group | Permissions | Purpose |
| :--- | :--- | :--- | :--- |
| `/opt/kijanikiosk/api/` | `kk-api:kk-api` | `750` | API service binaries and internal assets. |
| `/opt/kijanikiosk/payments/` | `kk-payments:kk-payments` | `750` | Payments service binaries. |
| `/opt/kijanikiosk/logs/` | `kk-logs:kk-logs` | `750` | Log aggregator scripts. |
| `/opt/kijanikiosk/config/` | `root:kijanikiosk` | `750` | Configuration and `.env` files (files inside are `640`). |
| `/opt/kijanikiosk/health/` | `root:kijanikiosk` | `750` | JSON health check outputs (files inside are `640`). |

## Shared Logs Directory (ACL Governed)
**Path:** `/opt/kijanikiosk/shared/logs/`
**Standard Ownership:** `kk-logs:kk-logs`
**Standard Permissions:** `2770` (SetGID applied so new files inherit `kk-logs` group).

**Access Control Lists (ACLs):**
* `u:kk-api:rwx` — API service can write and manage its own logs.
* `u:kk-payments:r-x` — Payments service can read API logs for correlation but cannot modify them.
* **Default ACLs:** `d:m:u:kk-api:rwx` & `d:m:u:kk-payments:r-x` — Ensures log files created dynamically by `logrotate` permanently inherit these precise access rights[cite: 48].
