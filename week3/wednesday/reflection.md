# Engineering Reflections: Package Management

## 1. The Idempotency Boundary
Three operations that are structurally harder to make idempotent in bash:
1. **Changing a running service's configuration:** To safely update a config, bash must detect the exact delta (not just whether the file exists), update it, and then conditionally trigger a service reload (`systemctl reload`) only if changes occurred.
2. **Rotating active credentials:** Bash must query a secret store, determine if the current key is expired, inject the new key, and coordinate a zero-downtime restart across multiple services, which requires complex state management.
3. **Rolling back package versions:** If a newer version is already installed, package managers naturally resist downgrades. A bash script must explicitly uninstall the current package, untangle dependencies, and force-install the older pinned version. 
Bash lacks a native state engine, so handling these requires writing complex, imperative "if/then" logic rather than simply declaring the desired end state.

## 2. Version Pinning vs Security Updates
Pinning is not a rejection of security updates; it is a rejection of *unpredictable* updates. If servers update themselves asynchronously via `apt upgrade`, staging and production will inevitably drift, causing deployment failures that outpace security threats. 
The correct operational process is to pin versions in the script (Infrastructure as Code). When a CVE drops, the engineering team updates the pinned version in the code, tests it in staging, and rolls it out to production deliberately. In a startup, this might involve manually running the updated script. In a mature enterprise, a dedicated security team uses automated CI/CD pipelines to scan for CVEs, automatically propose Pull Requests updating the pinned versions, and run integration tests before deploying.

## 3. systemd Hardening Trade-offs
The `ProtectSystem=strict` directive mounts the entire filesystem hierarchy (like `/`, `/usr`, and `/var`) as strictly read-only for the service process, overriding standard Linux file permissions. Therefore, when the app tries to write its PID and cache files to `/var/run/` and `/var/cache/`, the kernel blocks the write operations.
To fix this without removing the hardening, you must poke deliberate, granular holes in the read-only mount using the `ReadWritePaths=` directive. Adding `ReadWritePaths=/var/run/kijanikiosk/ /var/cache/kijanikiosk/` in the `[Service]` section allows the application to write exactly where it needs to while the rest of the system remains protected.

## 4. The Gap Between Shell Scripts and IaC Tools
1. **Removing Drifted State:** If an engineer manually creates a rogue user on the server, a bash script will ignore it. Tools like Terraform or Ansible can compare the live system against the declared state and automatically prune unmanaged resources.
2. **Complex Dependency Resolution:** If Phase 3 of a bash script fails, but Phase 4 doesn't check for it properly, it might execute and corrupt the system. IaC tools build native dependency graphs; if a parent resource fails, all dependent resources are automatically skipped.
3. **Cross-Node Orchestration:** Bash is inherently local. If provisioning the API server requires waiting for a database server to output an IP address, bash requires messy polling scripts. IaC tools natively manage outputs and dependencies across entirely different infrastructure layers.
Shell scripts are perfect for single-node bootstrapping or simple VM setup. IaC is required for evolving, multi-tier, or distributed infrastructure.
