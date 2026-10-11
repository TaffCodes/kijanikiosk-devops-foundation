# Engineering Reflection: Linux Permissions

## Question 1: The SUID Paradox
**Response to the colleague:**
While it is true that modern Linux kernels ignore the SUID bit on interpreted scripts (like `bash` or `python`) to prevent Time-of-Check to Time-of-Use (TOCTOU) race conditions, dismissing this finding is a dangerous oversight. 

First, the kernel's design decision exists because interpreting a script is a two-step process: the kernel elevates privileges and then calls the interpreter. In that microscopic window, an attacker could swap the script for a malicious binary, hijacking the elevated interpreter. 

Second, the combination of SUID and world-writable (`-rwsr-xrwx`) on `deploy.sh` is a critical vulnerability regardless of the kernel ignoring the bit. World-writable means any unprivileged user can overwrite the file's contents. If this script is executed by an automated system running as root (such as a root cron job, a systemd timer, or a CI/CD runner), the attacker simply injects a reverse shell into `deploy.sh`. When the root process blindly runs the script, the attacker's code executes with full root privileges, completely bypassing the need for the SUID bit to function.

## Question 2: Sudoers Policy Completeness
The suggested policy `amina ALL=(root) NOPASSWD: /bin/systemctl restart *` uses a shell wildcard. This does not just grant access to restart KijaniKiosk services; it grants Amina the ability to restart **any** service on the entire operating system as root.

**Abuse Scenarios Prevented:**
1. **Malicious Service Execution:** An attacker who compromises Amina's account could create a malicious systemd service file (e.g., `~/.config/systemd/user/root-shell.service`) that executes a privilege escalation payload. They could then run `sudo systemctl restart root-shell.service` (which matches the `*` wildcard) to execute their payload as root.
2. **Security Tooling Denial of Service:** An attacker could run `sudo systemctl restart sshd` to disrupt remote access for other administrators, or restart/stop firewall services (`ufw` or `iptables`) to drop the system's network defenses, opening ports that should be isolated.

## Question 3: nologin vs Locked Account
**Part A: Operational Difference**
Setting the shell to `/usr/sbin/nologin` prevents interactive shell access but leaves the account active, meaning the system (or root) can still seamlessly execute commands as that user via `sudo -u kk-api`. Locking the account with `passwd -l` modifies `/etc/shadow` by prepending a `!` to the password hash. This prevents password-based authentication entirely. 
In production, `/usr/sbin/nologin` is used for service accounts that need to run daemons but shouldn't have human logins. `passwd -l` is used when you need to temporarily suspend a human user (e.g., an employee on leave or terminated) without deleting their files.

**Part B: Operational Scenario Failure**
If `kk-api` is locked via `passwd -l`, the account is flagged as invalid for standard authentication. When the deployment pipeline attempts to run `sudo -u kk-api <startup_script>`, Pluggable Authentication Modules (PAM) — specifically the `account` requisite checks like `pam_unix.so` — will see the locked status in `/etc/shadow` and reject the session transition. 
The pipeline will fail instantly. The logs (`/var/log/auth.log`) will show an "account locked" or "authentication token manipulation error". A junior engineer would likely misdiagnose this as a file permission error (thinking `kk-api` doesn't have read/execute access to the script) and waste time running `chmod 777` on the application directory, rather than checking the account's locked status in `/etc/shadow`.

## Question 4: ACLs vs Group Redesign
Comparing the ACL approach (`setfacl` for specific users/groups) versus creating a single `kk-shared-logs` group:

1. **Security Isolation:** ACLs provide strict, granular isolation. `kk-api` gets write access, while `kk-payments` only gets read. A shared group forces a compromise: if the directory is group-writable so the API can write, then `kk-payments` implicitly gains write access too, violating the principle of least privilege.
2. **Auditability:** ACLs explicitly define exact intents per user/service, viewable directly via `getfacl`. A shared group obscures intent; you must cross-reference `ls -l` with `getent group` to figure out who actually has access, and it is impossible to tell *why* a specific user is in that group.
3. **Operational Complexity:** Groups are standard, natively understood by all Linux tools, and easily managed, but require users to re-login to inherit new group permissions. ACLs take effect instantly but are complex; they are hidden from standard `ls -l` output (indicated only by a `+`), and can be silently broken or masked if an engineer accidentally runs `chmod` on the directory without understanding the ACL mask behavior.
