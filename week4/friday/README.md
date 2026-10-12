# KijaniKiosk Full IaC Pipeline (Week 4 Capstone)

This repository contains the automated Infrastructure as Code (IaC) pipeline for the KijaniKiosk staging environment. It bridges infrastructure provisioning and server configuration into a single, idempotent workflow.

## Architecture Overview

1. **Infrastructure Provisioning (Terraform)**
   - Utilizes a reusable `app_server` module with a `for_each` loop to dynamically provision the API, Payments, and Logs servers on AWS (t3.micro).
   - Manages state collaboratively using a remote AWS S3 backend (`kijanikiosk-tfstate-matawi-2026`) with state locking capabilities.
   - Deploys strict AWS Security Groups allowing only inbound HTTP (80) and SSH (22) traffic.

2. **Dynamic Integration**
   - The infrastructure outputs are programmatically extracted by `pipeline.sh` and injected into an Ansible `inventory.ini` file, ensuring no hardcoded IPs exist in the configuration layer.

3. **Server Configuration (Ansible)**
   - Configures the raw Ubuntu servers to production standards using fully idempotent tasks.
   - Deploys hardened systemd unit files using Jinja2 templates (`ProtectSystem=strict`, `RestrictSUIDSGID=true`, `PrivateDevices=true`), achieving an exposure score below 2.5 for the payment service.
   - Enforces the principle of least privilege through dedicated service accounts, strict UFW firewall rules, and granular ACLs.

## Prerequisites

- **Terraform:** v1.6.0+
- **Ansible:** core 2.16+
- **AWS CLI:** Authenticated with sufficient privileges to provision EC2 instances and manage S3 buckets.
- **SSH Key:** An AWS key pair named `kijanikiosk-key` secured at `~/.ssh/kijanikiosk-key.pem` with `400` permissions.

## Execution

To deploy or reconcile the environment, run the master pipeline script from the `week4/friday/` directory:

```bash
./pipeline.sh
