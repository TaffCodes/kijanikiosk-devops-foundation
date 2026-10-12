# KijaniKiosk Production Server Foundation

This directory contains the Week 3 independent project deliverables for the KijaniKiosk DevOps foundation. The objective is to provide a monolithic, idempotent bash script that provisions a production-grade Linux server from a "dirty" state, configures strict systemd hardening, establishes a secure ACL-based access model, and sets up robust log rotation.

## File Manifest
* **`kijanikiosk-provision.sh`**: The master 8-phase idempotent provisioning script.
* **`pre-provisioning-audit.txt`**: Initial state audit of the VM before provisioning.
* **`provision-run-dirty.log`** & **`provision-run-clean.log`**: Execution logs demonstrating idempotency and dirty-state convergence.
* **`access-model-final.md`**: Documentation of the system's users, groups, and ACLs.
* **`integration-notes.md`**: Engineering decisions and conflict resolutions across system layers.
* **`kk-payments-hardening.md`**: Iterative systemd security hardening log for the payments service (Score: 1.8).
* **`hardening-decisions.md`**: Executive-level security posture summary for stakeholders.
* **`post-remediation-verification.txt`**: Final verification proofs, including the logrotate access preservation test.

## Usage
To provision or reconcile the server state, execute the script as root:
```bash
sudo bash kijanikiosk-provision.sh
```
