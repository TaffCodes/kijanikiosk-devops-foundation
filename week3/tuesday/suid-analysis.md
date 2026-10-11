# SUID Analysis

**1. Why does the kernel ignore SUID on interpreted scripts?**
Modern Linux kernels ignore the SUID bit on interpreted scripts (files starting with `#!`) to prevent a severe Time-of-Check to Time-of-Use (TOCTOU) race condition. When a script with SUID is executed, the kernel checks the permissions, elevates privileges, and then invokes the interpreter (e.g., `/bin/bash`). Because this is a multi-step process, an attacker could manipulate a symlink to point to a malicious file during the microsecond window between the kernel's permission check and the interpreter opening the file, forcing the interpreter to run malicious code as root.

**2. If the SUID bit has no effect on this script, why is the combination of SUID + world-write still a critical finding?**
World-write allows any unprivileged user on the system to completely overwrite the contents of the script. The presence of the SUID bit, even if ignored by the kernel, indicates a clear operational intent that this script is meant to perform privileged deployment actions. It is a massive red flag pointing to systemic misconfiguration.

**3. What would make this scenario exploitable in practice?**
The scenario becomes a direct path to root compromise if an automated process running as root (such as a system `cron` job, a systemd service, or a CI/CD pipeline agent like Jenkins) routinely executes this script. Because the script is world-writable, an attacker simply injects a reverse shell or malicious commands into `deploy.sh`. The next time the root-level cron job executes the script, it blindly executes the attacker's payload with full root privileges.
