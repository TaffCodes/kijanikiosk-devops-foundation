# kk-payments Hardening Log

**Starting Score (No Hardening):** ~9.6 (UNSAFE)

| Directive Added | New Score | Reason for Inclusion |
| :--- | :--- | :--- |
| `NoNewPrivileges=true` | 8.2 | Prevents the process from escalating privileges via SUID binaries. |
| `PrivateTmp=true` | 7.5 | Isolates `/tmp` to prevent temp-file symlink attacks. |
| `ProtectSystem=strict` | 5.8 | Mounts the OS file system strictly read-only for this process. |
| `ProtectHome=true` | 4.9 | Prevents access to `/home`, protecting user credentials. |
| `CapabilityBoundingSet=` | 4.1 | Drops all root capabilities (e.g., `CAP_NET_ADMIN`). |
| `MemoryDenyWriteExecute=true` | 3.6 | Prevents memory from being both writable and executable (blocks shellcode). |
| `LockPersonality=true` | 3.2 | Locks the kernel execution domain. |
| `RestrictRealtime=true` | 2.9 | Prevents the process from hogging CPU scheduling. |
| `RestrictNamespaces=true` | 2.7 | Prevents the service from creating new namespace isolation layers. |
| `ProtectKernelTunables=true` | 2.5 | Mounts `/proc/sys` read-only. |
| `ProtectControlGroups=true` | 2.3 | Mounts `/sys/fs/cgroup` read-only. |
| `SystemCallFilter=@system-service` | **1.8 (SAFE)** | Safelist of standard system calls, dropping dangerous ones like `ptrace`. |

### Rejected Directives
1. **`PrivateUsers=true`:** I investigated this to map the service user to a dummy root user, but rejected it because our architecture explicitly relies on cross-user ACLs in the shared log directory. Masking the user ID could silently break our access model.
2. **`ProtectClock=true`:** Rejected because the payments service requires extremely precise cryptographic timestamping for financial transactions. Denying access to clock syncing could potentially cause transaction drift during high-load periods.
