# Incident Runbook: KijaniKiosk Staging 502s

**Investigation Start Time:** 07:43
*I have read the setup script. I understand what it does in general terms. I commit to treating the server as a black box during investigation and not referring back to the script until my runbook is complete.*

## Phase 1: Performance Layer
* **`top` findings:** The system shows massive I/O wait (wa is extremely high). Processes are entering state D (uninterruptible sleep), meaning they are blocked waiting for disk I/O.
* **`vmstat` findings:** The `b` column shows blocked processes consistently, confirming sustained I/O saturation rather than a brief spike.
* **`iostat` findings:** The primary disk shows near 100% `%util` with extremely high `await` times (latency). The `wkB/s` indicates a heavy write workload.

**Initial Hypothesis:** I believe the 502 errors are caused by severe disk I/O saturation suggesting that the `kk-payments` service (or a related process) is blocking on disk writes, causing requests to time out. My next step is to check the application and system logs to confirm what is writing so aggressively to the disk.

## Phase 2: Log Layer
* **`journalctl` findings:** The `kk-payments` service is throwing `SQLITE_IOERR` database write errors, confirming that the service cannot write to disk due to I/O saturation.
* **Kernel logs:** The kernel is actively reporting I/O errors.
* **Disk Usage:** Running `du -sh` on the shared logs directory reveals massive gigabyte-sized log files (`payments-2024-03-*.log`) that have accumulated over days.
* **Logrotate Config:** The `/etc/logrotate.d/kijanikiosk` file is missing entirely.

**Revised Hypothesis:** The 502 errors are a symptom of a cascading failure. A missing `logrotate` policy caused application logs to accumulate massively over several days. This completely saturated the disk's write capacity. Consequently, the `kk-payments` service is failing to write transaction data to its SQLite database, timing out, and returning 500-level errors to Nginx, which surfaces them as 502 Bad Gateway to the user. My next step is to check the network layer to see if anything else is compounding this failure.

## Phase 3: Network Layer
* **`ss` findings:** Port 3001 is bound to a rogue `node` process (`/tmp/rogue-server.js`) rather than the expected `kk-payments` service.
* **`curl` findings:** Reaching out to `localhost:3001` returns a hardcoded `500 Internal Server Error` from the rogue test server. 
* **`ufw` findings:** There is an active `DENY IN` rule for port 3001 blocking external health checks.

**Final Diagnosis:**
1. **Log/IO Fault:** Unrotated logs saturated the disk.
2. **Port Conflict:** A leftover development server hijacked port 3001, causing Nginx to proxy legitimate requests to a script that returns 500s.
3. **Firewall Fault:** A rogue `DENY 3001` rule is blocking upstream monitoring systems from reaching the endpoint, causing the load balancer to mark the node as unhealthy.

## Phase 4: Remediation
1. **Port Conflict:** Ran `sudo ss -tlnp | grep 3001` to find the rogue PID, then used `sudo kill <PID>` (SIGTERM) to terminate it gracefully. Verified port release.
2. **Firewall Rule:** Ran `sudo ufw delete deny 3001/tcp` and verified removal with `sudo ufw status verbose`.
3. **Log Accumulation:** Created `/etc/logrotate.d/kijanikiosk` with a `daily` rotation schedule. Ran `sudo logrotate --force /etc/logrotate.d/kijanikiosk` to compress the 1.5GB of logs instantly and relieve disk pressure.

**Fix Order Rationale:**
I executed the fixes in this specific order to minimize risk and restore service fastest:
* **First:** The port conflict was the fastest fix (seconds) and immediately stopped Nginx from returning 502s from the rogue server.
* **Second:** The firewall rule was removed to restore health checks, allowing the upstream load balancer to see the node as healthy again.
* **Third:** Log rotation was performed last because compressing gigabytes of logs creates a massive CPU and I/O spike. Running this first would have exacerbated the immediate performance degradation while the other faults were still active.

## Phase 5: Prevention & Verification
**Prevention Measures:**
1. **Log Accumulation:** Added a daily `logrotate` configuration to the `kijanikiosk-provision.sh` script to ensure logs are compressed automatically before they can saturate the disk.
2. **Firewall Rule:** Added a strict warning comment in the provisioning script to prevent engineers from blindly blocking port 3001 during security hardening.
3. **Port Conflict:** Moving forward, rogue development servers should not be run on staging. Production instances are managed exclusively via `systemd`, which provides isolated port binding.

**Verification:** All metrics have returned to baseline. I/O wait is normal, disk space is reclaimed, port 3001 is clear of rogue processes, and the health check firewall block is removed.
