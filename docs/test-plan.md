# Pre-Review Verification & Peer Test Plan

Prepared prior to the peer review session to systematically validate all four Track A layers (Infrastructure, Runtime, Delivery, Intelligence).

## Test Cases Executed During Peer Review

| Test ID | Layer | Verification Procedure | Expected Outcome |
| :--- | :--- | :--- | :--- |
| **TC-01** | Infrastructure (Terraform + Ansible) | Run `terraform apply` and `ansible-playbook -i inventory.ini site.yml` from a clean state. | `kijani-staging` namespace, `kijani-staging-quota`, pull secrets, and S3 bucket folders exist with zero errors. |
| **TC-02** | Runtime (ConfigMap Separation) | Deploy `k8s/kk-payments-deployment.yaml` to both `kijani-staging` and `default` and query `/health`. | Staging returns `postgres-staging.kijani-staging.svc.cluster.local`; production returns `postgres-prod.default.svc.cluster.local`. |
| **TC-03** | Delivery (Smoke Test & Gate) | Execute `./scripts/smoke-test.sh kijani-staging staging 13001` and inspect Jenkins approval gate stage. | Smoke test exits `0`; approval gate prompts for and records `APPROVAL_REASON`. |
| **TC-04** | Intelligence (Serverless Receipt Chain) | Send `POST /pay` to staging service and inspect `/var/lib/kijanikiosk/s3/kk-payments-receipts-staging-processed/`. | `<receiptId>.json` and `<receiptId>-notified.json` are generated with `notificationStatus: "DISPATCHED"`. |
| **TC-05** | Intelligence (Prometheus Alerting & Fault) | Send `POST /simulate-fault {"enable": true}` and evaluate `prometheus/alert-rules.yml`. | `kk_payments_errors_total` increments above threshold and `KkPaymentsHighErrorRate` alert fires. |
