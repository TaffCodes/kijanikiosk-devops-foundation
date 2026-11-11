# AI Tooling Integration and Governance Log

This log documents AI-assisted engineering artifacts using the mandatory Week 10 eight-field governance format and evaluates each output against the six-point governance checklist:
1. No hardcoded credentials or secrets
2. Least-privilege execution (non-root user / scoped permissions)
3. Explicit resource requests and limits
4. Environment configuration decoupled from code/manifests
5. Deterministic version pinning (no `:latest` tags)
6. Automated health/readiness verification and error handling

## Entry 1: Kubernetes Multi-Environment Deployment Manifest (`k8s/kk-payments-deployment.yaml`)

| Field | Governance Record |
| :--- | :--- |
| **1. Date & Component** | 2026-11-09 — `k8s/kk-payments-deployment.yaml` & `k8s/configmap-staging.yaml` |
| **2. Prompt / Task Given to AI** | "Generate a Kubernetes Deployment manifest for `kk-payments` that can be deployed to both `kijani-staging` and `default` namespaces using environment-specific ConfigMaps for `DB_HOST`." |
| **3. What the AI Produced** | The AI generated a `Deployment` manifest containing `namespace: kijani-staging` hardcoded inside `metadata`, used `image: localhost:5000/kk-payments:latest`, hardcoded `DB_HOST` directly inside the `env:` array of the container spec, and omitted `securityContext` and `readinessProbe`. |
| **4. What the AI Got Wrong** | First, hardcoding `namespace: kijani-staging` in `metadata` broke the Track A requirement to reuse the exact same Deployment manifest across both `kijani-staging` and `default` namespaces. Second, hardcoding `DB_HOST` in the Pod spec violated configuration separation. Third, using the `:latest` image tag broke rollback traceability and omitted `runAsNonRoot` security hardening. |
| **5. Specific Reviewer Changes Made** | Removed `namespace:` from `metadata` so target namespaces are passed via `kubectl apply -n <namespace>`; replaced the inline `env:` block with `envFrom: [{ configMapRef: { name: kk-payments-config } }]`; pinned the image to `localhost:5000/kk-payments:1.0.0`; added `securityContext: { runAsNonRoot: true, runAsUser: 1000 }`; and added both `livenessProbe` and `readinessProbe` on `/health`. |
| **6. Governance Checklist Item Referenced** | Checklist Item #2 (Least-privilege non-root execution), Item #3 (Explicit CPU/memory requests and limits), Item #4 (Environment configuration decoupled via ConfigMaps), and Item #5 (Deterministic version pinning). |
| **7. Verification Method** | Applied the identical manifest to both `-n kijani-staging` and `-n default` and verified via `scripts/smoke-test.sh` that `/health` returned `postgres-staging.kijani-staging.svc.cluster.local` in staging and `postgres-prod.default.svc.cluster.local` in production. |
| **8. Reviewer Sign-Off** | Ray Ntabo Basweti-Mobe — Verified in commit history (`feature/capstone-infra-runtime`). |

## Entry 2: Jenkins Pipeline Approval Gate & Staging Smoke Test (`Jenkinsfile`)

| Field | Governance Record |
| :--- | :--- |
| **1. Date & Component** | 2026-11-10 — `Jenkinsfile` & `scripts/smoke-test.sh` |
| **2. Prompt / Task Given to AI** | "Write a declarative Jenkinsfile that deploys `kk-payments` to `kijani-staging`, runs a smoke test, and pauses for a production approval gate before deploying to `default`." |
| **3. What the AI Produced** | The AI generated a `Jenkinsfile` with a basic `input message: 'Approve production?'` step that had no input parameters, placed the approval gate *before* the staging smoke test finished, and checked only `kubectl get pods` instead of testing the HTTP `/health` and `/pay` receipt chain endpoints. |
| **4. What the AI Got Wrong** | Using a bare `input` step without a `parameters` block meant Jenkins did not capture or log an approval reason string (failing the Dimension 2 requirement to record an approval reason). Furthermore, checking `kubectl get pods` only proves container processes started, not that the staging ConfigMap `DB_HOST` or the `kk-payments-receipts-staging` serverless receipt chain actually worked. |
| **5. Specific Reviewer Changes Made** | Reordered the pipeline stages so `Staging Smoke Test & Receipt Chain Check` must exit `0` before the `Production Approval Gate` stage is evaluated; added a mandatory `string(name: 'APPROVAL_REASON', ...)` parameter to the `input` step and logged `[AUDIT LOG] Production deployment approved. Reason: ${approvalReason}`; and wrote `scripts/smoke-test.sh` to verify HTTP `/health`, `DB_HOST`, `POST /pay`, and the output file in `kk-payments-receipts-staging-processed`. |
| **6. Governance Checklist Item Referenced** | Checklist Item #1 (No hardcoded credentials in Jenkinsfile) and Item #6 (Automated health/readiness verification and error handling prior to production promotion). |
| **7. Verification Method** | Executed the pipeline script and verified that a simulated smoke test failure aborts the pipeline prior to the approval gate, while a passing run captures and prints the operator's approval reason string. |
| **8. Reviewer Sign-Off** | Ray Ntabo Basweti-Mobe — Verified in commit history (`feature/capstone-pipeline-observability`). |
