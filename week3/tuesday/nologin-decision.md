# Shell Decision: /usr/sbin/nologin vs /bin/false

For the KijaniKiosk service accounts (`kk-api`, `kk-payments`, `kk-logs`), I configured `/usr/sbin/nologin` as the default shell instead of `/bin/false`. 

**The Mechanism and Reasoning:**
While both options prevent a user from obtaining an interactive shell, `/usr/sbin/nologin` is explicitly designed for service account management. When an interactive login attempt is made (such as via SSH), `/usr/sbin/nologin` safely rejects the login, displays a polite rejection message, and gracefully exits. It effectively blocks interactive shell drops while still allowing the system or administrators to execute background service processes using `sudo -u <service_account> <command>`. 

In contrast, `/bin/false` is a generic binary that silently exits with a status code of 1. While slightly more restrictive, it provides no feedback on rejected login attempts, which can complicate troubleshooting. Therefore, `/usr/sbin/nologin` provides the exact security isolation required for these daemon accounts without sacrificing operational visibility.
