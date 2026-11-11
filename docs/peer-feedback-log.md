# Peer Review & Testing Feedback Log (CAP-5)

**Peer Reviewer:** Job Mainye (DevOps Peer Review Session)  
**Test Plan Used:** `docs/test-plan.md`

| # | Issue Identified During Peer Review | Severity | Resolution Implemented | Verification Evidence |
| :--- | :--- | :--- | :--- | :--- |
| **1** | **GitHub Issue #1:** `readinessProbe` in `k8s/kk-payments-deployment.yaml` initially had `initialDelaySeconds: 30`, causing `scripts/smoke-test.sh` to wait excessively during rapid staging rollouts. | **Medium** | Reduced `readinessProbe.initialDelaySeconds` from `30` to `5` and `periodSeconds` to `5` in `k8s/kk-payments-deployment.yaml`, reducing rollout readiness time to under 10 seconds. | Closed via commit `0c90678` (`fix(k8s): tune readinessProbe initialDelaySeconds to 5s for faster rollout (closes #1)`) — before/after diff visible via `git show 0c90678`. |
| **2** | **GitHub Issue #2:** `prometheus/alert-rules.yml` initially used a 15-minute evaluation window (`[15m]`) for `KkPaymentsHighErrorRate`, which was too slow to demonstrate firing during a 5-minute live presentation. | **High** | Updated `KkPaymentsHighErrorRate` expression to `increase(kk_payments_errors_total[1m]) >= 3` with `for: 10s` so deliberate fault injection triggers the alert reliably during the live demo. | Resolved in `prometheus/alert-rules.yml` via commit `c162240` (`feat(monitoring): add prometheus scrape config and kk-payments alert rules (closes #2)`). |
| **3** | **GitHub Issue #3:** `scripts/smoke-test.sh` did not terminate background `kubectl port-forward` processes if a curl assertion failed mid-script, leaving port `13001` bound on retry. | **Low** | Added `trap 'kill ${PF_PID} 2>/dev/null || true' EXIT` immediately after starting `kubectl port-forward` so the background socket is always cleaned up on exit. | Resolved in `scripts/smoke-test.sh` via commit `319e7b2` (`test(smoke): add automated staging smoke test and receipt chain verifier (closes #3)`). |
