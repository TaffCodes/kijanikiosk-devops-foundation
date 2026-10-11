# systemd Security Analysis

After applying the baseline hardening directives (`NoNewPrivileges`, `PrivateTmp`, `ProtectSystem`, `ProtectHome`, `CapabilityBoundingSet`), the systemd security score significantly improved. To drop the score further, I added two additional directives based on the `systemd-analyze security` recommendations.

## Additional Hardening Directives

1. **`MemoryDenyWriteExecute=true`**
   * **What it does:** It prevents the service from creating memory mappings that are simultaneously writable and executable.
   * **Why I chose it:** This is a crucial defense against memory corruption exploits, such as buffer overflows, where an attacker injects executable code into memory and then executes it. Since standard Node.js API services do not typically need to compile or execute arbitrary memory on the fly (unlike JIT compilers in some contexts), this drastically reduces the attack surface without breaking the app.

2. **`LockPersonality=true`**
   * **What it does:** It prevents the service process from changing its execution domain (personality system call).
   * **Why I chose it:** The Linux personality system allows a process to alter its execution environment to emulate other Unix-like systems (like 32-bit compatibility on a 64-bit kernel). Attackers often abuse this feature to bypass security mechanisms or exploit kernel vulnerabilities specific to older architectures. Locking it ensures the Node.js process stays strictly within the standard Linux execution domain.
