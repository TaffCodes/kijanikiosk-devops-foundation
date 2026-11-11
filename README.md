# KijaniKiosk End-to-End Production Delivery Platform (Track A: Infrastructure-First)

An end-to-end, multi-environment DevOps delivery platform for the `kk-payments` microservice, integrating Terraform namespace provisioning, Ansible configuration management, Kubernetes multi-environment ConfigMap isolation, Jenkins CI/CD with automated smoke tests and approval gates, the Week 10 serverless receipt chain, and Prometheus alerting.

## 1. Architecture Overview

The platform is organized into four decoupled layers (`docs/scope.md` & `docs/architecture.png`):
1. **Infrastructure Layer (`terraform/` & `ansible/`):** Terraform provisions the isolated `kijani-staging` namespace and resource quotas; Ansible configures S3 bucket storage (`/var/lib/kijanikiosk/s3/kk-payments-receipts-staging`), registry secrets, and environment-specific ConfigMaps.
2. **Runtime Layer (`k8s/`):** Runs `kk-payments` across `kijani-staging` and `default` (production) using the **exact same `k8s/kk-payments-deployment.yaml` manifest** while injecting environment-specific `DB_HOST` and `RECEIPT_BUCKET` values from `kk-payments-config`.
3. **Delivery Layer (`Jenkinsfile` & `scripts/smoke-test.sh`):** Automatically deploys to `kijani-staging` on merge to `main`, executes `scripts/smoke-test.sh`, and enforces a human approval gate (recording an audit reason) before promoting to `default`.
4. **Intelligence & Event Layer (`serverless/` & `prometheus/`):** Staging payments write JSON receipts to `kk-payments-receipts-staging`, triggering the 3-stage Week 10 receipt chain (`kk-receipt-generator` -> `kk-fraud-validator` -> `kk-notifier`), while Prometheus evaluates alert rules in `prometheus/alert-rules.yml`.

## 2. Repository Directory Structure

```text
.
├── Dockerfile.production          # Multi-stage sub-100MB production container build (runs as kijani)
├── Jenkinsfile                    # End-to-end CI/CD pipeline with smoke test & approval gate
├── package.json                   # Node.js service dependencies and build scripts
├── src/
│   └── index.js                   # kk-payments microservice with /health, /pay, /metrics, /simulate-fault
├── terraform/
│   ├── main.tf                    # Provisions kijani-staging namespace & ResourceQuota
│   ├── variables.tf               # Configurable kubeconfig and namespace parameters
│   └── outputs.tf                 # Outputs provisioned namespace name
├── ansible/
│   ├── inventory.ini              # Local control node inventory
│   └── site.yml                   # Configures S3 buckets, registry secrets, and ConfigMaps
├── k8s/
│   ├── configmap-staging.yaml     # Staging ConfigMap (postgres-staging DB_HOST & staging bucket)
│   ├── configmap-prod.yaml        # Production ConfigMap (postgres-prod DB_HOST & prod bucket)
│   ├── kk-payments-deployment.yaml# Shared multi-environment Deployment with probes & limits
│   └── kk-payments-service.yaml   # ClusterIP Service exposing port 3001
├── serverless/
│   ├── serverless.yml             # Week 10 Serverless Framework definition
│   ├── handler.js                 # Receipt generator, fraud validator, and customer notifier
│   └── run-receipt-chain.js       # Local event runner triggered on S3 receipt creation
├── prometheus/
│   ├── prometheus.yml             # Scrape configurations for staging and production
│   └── alert-rules.yml            # Alert rules for error rate, latency, and pod restarts
├── scripts/
│   └── smoke-test.sh              # Automated smoke test verifying health, DB_HOST, and receipt chain
└── docs/
    ├── scope.md                   # 1-page Scope Document & labeled Mermaid architecture diagram
    ├── architecture.png           # Rendered architecture diagram image
    ├── ai-governance-log.md       # Week 10 eight-field AI governance audit log
    ├── test-plan.md               # Pre-session verification test plan
    ├── peer-feedback-log.md       # Peer review log with severity, resolution & issue links
    └── reflection.md              # 1-page engineering reflection
```

## 3. Prerequisites

* Docker `>= 24.0` and local registry running on `localhost:5000`
* Minikube `>= 1.32` and `kubectl` configured (`kubectl get nodes` Ready)
* Terraform `>= 1.3` and Ansible `>= 2.14`
* Node.js `>= 18.x` and Jenkins `>= 2.400`

## 4. End-to-End Setup & Reproduction Steps (Clean Checkout)

```bash
# 1. Provision kijani-staging namespace with Terraform
(cd terraform && terraform init && terraform apply -auto-approve)

# 2. Configure S3 receipt buckets, registry secrets, and ConfigMaps with Ansible
(cd ansible && ansible-playbook -i inventory.ini site.yml)

# 3. Build and push the production container image
docker build --no-cache -t localhost:5000/kk-payments:1.0.0 -f Dockerfile.production .
docker push localhost:5000/kk-payments:1.0.0

# 4. Deploy identical manifest to kijani-staging and default namespaces
kubectl apply -f k8s/kk-payments-deployment.yaml -n kijani-staging
kubectl apply -f k8s/kk-payments-service.yaml -n kijani-staging
kubectl apply -f k8s/kk-payments-deployment.yaml -n default
kubectl apply -f k8s/kk-payments-service.yaml -n default
```

## 5. Running Verification & Smoke Tests

```bash
# Run staging smoke test (verifies staging DB_HOST + serverless receipt chain)
./scripts/smoke-test.sh kijani-staging staging 13001

# Run production smoke test (verifies production DB_HOST + production receipt chain)
./scripts/smoke-test.sh default production 13002
```

## 6. Fault Simulation & Alert Verification

To demonstrate fault handling and Prometheus alert evaluation during a live presentation:

```bash
kubectl port-forward svc/kk-payments-service -n kijani-staging 13001:3001 &
curl -X POST http://127.0.0.1:13001/simulate-fault -H "Content-Type: application/json" -d '{"enable": true}'
curl -i http://127.0.0.1:13001/health
curl -s http://127.0.0.1:13001/metrics | grep kk_payments_errors_total
# Restore normal service:
curl -X POST http://127.0.0.1:13001/simulate-fault -H "Content-Type: application/json" -d '{"enable": false}'
```

## 7. AI Governance, Testing & Known Production Gaps

* **AI Governance:** See [`docs/ai-governance-log.md`](docs/ai-governance-log.md) for full critiques and remediations of AI-generated manifests and pipeline stages.
* **Testing & Peer Feedback:** See [`docs/test-plan.md`](docs/test-plan.md) and [`docs/peer-feedback-log.md`](docs/peer-feedback-log.md).
* **Known Production Gaps & Remediations:**
  1. *Secret Management:* Database connection strings and registry tokens currently rely on standard Kubernetes Secrets and ConfigMaps; production remediation is integrating **External Secrets Operator** backed by HashiCorp Vault.
  2. *Storage Backend:* Receipt storage uses a host-mounted S3 directory on single-node Minikube; production remediation is migrating to **AWS S3 with IAM Roles for Service Accounts (IRSA)**.
