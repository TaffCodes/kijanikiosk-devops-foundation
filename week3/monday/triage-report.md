# KijaniKiosk API Server - Triage Report
**Date:** October 11, 2026
**Investigated by:** Ray Basweti
**Server:** 820-G3
**Incident start (approximate):** 2026-10-10 03:45:10 UTC

## Summary
The KijaniKiosk API server is experiencing critical service degradation driven by two distinct issues: an exhausted PostgreSQL connection pool that culminated in total database unavailability (`ECONNREFUSED` on port 5432), and severe memory pressure caused by an unmanaged background Python process holding over 500MB of allocated memory. Additionally, log disk usage is elevated due to an unrotated 267MB raw access log (`access.log.1`) in `/var/log/kijanikiosk/`.

## Process and Resource State
* **Top Memory Consumers:**
  * `python3` (PID active from setup): Holding ~500MB RSS (~12-15% resident memory consumption).
  * System worker processes and NGINX master/worker processes operating normally.
* **Process States:**
  * Checked process states using `ps aux | awk '$8 ~ /[ZD]/'`. No zombie (`Z`) or uninterruptible sleep (`D`) processes were detected.
* **Memory Pressure:**
  * `free -h` and `/proc/meminfo` show reduced `MemAvailable` due to the rogue Python background allocation combined with application worker heap pressure flagged at 04:09:12 (warning at 87% memory utilization).

## Filesystem and Disk
* **Partition Status:** Root filesystem `/` remains below the critical 80% threshold, but `/var/log` exhibits unmonitored growth.
* **Large Files:**
  * File: `/var/log/kijanikiosk/access.log.1`
  * Size: ~267 MB (generated via unrotated raw streaming).
* **Implication:** If log rotation (`logrotate`) is not configured for the KijaniKiosk custom directory, future traffic bursts will drive the root disk into full capacity, risking system-wide I/O lockups.

## Log Analysis
* **Timeline of Failure (from `/var/log/kijanikiosk/app.log`):**
  * `03:14:22`: Normal baseline operational state (`/api/products` responded in 112ms).
  * `03:45:10`: Initial warning — Database connection pool reached 85% capacity.
  * `04:01:33`: Connection pool warning escalated to 94% capacity.
  * `04:07:55`: Critical threshold reached — Connection pool exhausted, requests began queuing.
  * `04:08:01`: Cascading cascading query timeouts (`SELECT * FROM orders` and `SELECT * FROM products` timed out after 30000ms), explaining the P95 latency surge to ~480ms.
  * `04:09:12`: App worker warning — Memory reached 87%.
  * `06:22:18` - `06:22:28`: Complete database outage (`ECONNREFUSED database:5432`), retry limits reached.
* **Root Log Signal:** The issue began as connection pooling exhaustion (leak or long-running unindexed queries) and degraded into a hard crash or process termination of the PostgreSQL instance at port 5432.

## Network and Service State
* **Port Bindings (`ss -tlnp`):**
  * Port 80 (NGINX) is active and bound to `0.0.0.0:80`.
  * Port 5432 (PostgreSQL) is completely absent from listening sockets.
* **HTTP Latency Check:**
  * `curl -o /dev/null -s -w "HTTP %{http_code} | Total Time: %{time_total}s\n" http://localhost/` returns HTTP 200/502 depending on proxy pass backend status.
* **TCP Connection Health:**
  * No significant lingering `CLOSE_WAIT` or `TIME_WAIT` connection spikes, confirming the network layer is healthy and the blockage is backend application/database service-bound.

## Assessment
The P95 latency degradation from ~120ms to ~480ms was initially caused by query queuing and 30-second timeouts after the database connection pool became saturated at 04:07:55. This saturation held Node.js worker event loops open, leading to memory accumulation. The degradation escalated to full API failure after 06:22:18 when the PostgreSQL database on port 5432 stopped accepting connections entirely. A co-located rogue Python process consuming ~500MB exacerbated system memory pressure.

## Recommended Next Steps
1. **Restore & Stabilize Database Service:** Investigate why PostgreSQL on port 5432 terminated (check `/var/log/postgresql/` or systemd status via `systemctl status postgresql`), bring the database back online, and review connection pool sizing and connection leak hygiene in the application code.
2. **Terminate Rogue Background Process:** Terminate the high-memory `python3` consumer process (`kill -9 <PID>`) to reclaim ~500MB of resident RAM and prevent further worker memory pressure.
3. **Implement Log Rotation & Cleanup:** Configure a `/etc/logrotate.d/kijanikiosk` policy with gzip compression and retention caps to truncate `/var/log/kijanikiosk/access.log.1` and prevent storage exhaustion.
