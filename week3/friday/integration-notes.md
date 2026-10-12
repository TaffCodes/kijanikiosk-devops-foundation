# Integration Notes: Conflict Resolution

## Challenge A: ProtectSystem=strict and the EnvironmentFile
* **The Conflict:** `ProtectSystem=strict` mounts `/usr`, `/boot`, and `/etc` as read-only[cite: 52]. If configuration files are placed in `/etc/kijanikiosk`, the service might be blocked from reading or writing to them.
* **The Resolution:** I kept the `.env` files in `/opt/kijanikiosk/config/` and secured them with `640` permissions, owned by `root:kijanikiosk`. `systemd` reads the `EnvironmentFile` as root *before* transitioning to the restricted service user context[cite: 47, 52]. Therefore, the read-only file system restriction does not block the environment variables from loading.

## Challenge B: The Monitoring User and ACL Defaults
* **The Conflict:** The new `health` directory needs to be written to by the root provisioning script but read by the monitoring system (and the `amina` user) without requiring `sudo`[cite: 52].
* **The Resolution:** I created `/opt/kijanikiosk/health/` with ownership `root:kijanikiosk` and permissions `750`. I specifically explicitly set the `last-provision.json` file to `640` permissions owned by `kk-logs:kijanikiosk`[cite: 46]. Because `amina` is part of the `kijanikiosk` group, she can seamlessly read the health check file without needing extended ACLs[cite: 52].

## Challenge C: logrotate postrotate and PrivateTmp
* **The Conflict:** `logrotate` requires a `postrotate` script to signal the application to release its old file handles. However, the `kk-logs` service has `PrivateTmp=true` and `ProtectSystem=strict`[cite: 52].
* **The Resolution:** Because simple Node.js scripts do not natively handle `SIGHUP` for log rotation unless explicitly programmed to do so, I opted to use `systemctl reload kk-logs.service || true` in the logrotate block[cite: 52, 53]. The unit file is configured with `ExecReload=/bin/kill -HUP $MAINPID`. If the application fails to drop the file handle, it will gracefully fall back without breaking the rotation cycle.

## Challenge D: The Dirty VM and Package Holds
* **The Conflict:** When the script runs on Friday's VM, Nginx and Node.js are already installed. Running `apt-get install` blindly could attempt a version downgrade or cause apt lock conflicts[cite: 53].
* **The Resolution:** I implemented a programmatic version check using `dpkg -l` combined with `apt-mark showhold`[cite: 53]. If the packages are already present and pinned, the script deliberately skips the installation step, preventing unnecessary package manager churn and respecting the existing system state.
