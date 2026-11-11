#!/usr/bin/env bash
set -euo pipefail

run_cmd() {
  echo -e "\033[1;32mmatawi@kijanikiosk\033[0m:\033[1;34m~\033[0m$ $*"
  eval "$@"
}

next_stage() {
  echo ""
  read -r -p ">>> Press [ENTER] to execute next verification stage..."
  echo ""
}

clear
echo "================================================================================"
echo " KIJANIKIOSK PRODUCTION DELIVERY PIPELINE — TRACK A (INFRASTRUCTURE-FIRST)"
echo " Architecture: IaC (Terraform/Ansible) -> K8s Runtime -> Jenkins -> Observability"
echo "================================================================================"

next_stage
echo "--------------------------------------------------------------------------------"
echo " [STAGE 1/6] INFRASTRUCTURE LAYER: Terraform Namespace & Ansible Configuration"
echo " Trade-Off: Single-Cluster Namespace Isolation Mitigated by Hard ResourceQuotas"
echo "--------------------------------------------------------------------------------"
run_cmd "kubectl get namespace kijani-staging --show-labels"
echo ""
run_cmd "kubectl get resourcequota kijani-staging-quota -n kijani-staging"
echo ""
run_cmd "ls -la /var/lib/kijanikiosk/s3/"

next_stage
echo "--------------------------------------------------------------------------------"
echo " [STAGE 2/6] RUNTIME LAYER: Shared Deployment Manifest & Isolated ConfigMaps"
echo " Parity Check: Identical Image (1.0.0) & Spec, Separate DB_HOST & Receipt Bucket"
echo "--------------------------------------------------------------------------------"
run_cmd "kubectl get pods -n kijani-staging -o wide"
echo ""
run_cmd "kubectl get pods -n default -o wide"
echo ""
echo "--- Staging ConfigMap (kijani-staging) ---"
run_cmd "kubectl get configmap kk-payments-config -n kijani-staging -o jsonpath='{.data}' && echo ''"
echo ""
echo "--- Production ConfigMap (default) ---"
run_cmd "kubectl get configmap kk-payments-config -n default -o jsonpath='{.data}' && echo ''"

next_stage
echo "--------------------------------------------------------------------------------"
echo " [STAGE 3/6] DELIVERY & EVENT LAYER: Staging Smoke Test & Serverless Chain"
echo " Flow: POST /pay -> kk-payments-receipts-staging -> Generator -> Fraud -> Notifier"
echo "--------------------------------------------------------------------------------"
run_cmd "./scripts/smoke-test.sh kijani-staging staging 13001"
echo ""
LATEST_RECEIPT=$(ls -t /var/lib/kijanikiosk/s3/kk-payments-receipts-staging-processed/*-notified.json | head -n 1)
run_cmd "cat ${LATEST_RECEIPT}"

next_stage
echo "--------------------------------------------------------------------------------"
echo " [STAGE 4/6] PRODUCTION APPROVAL GATE & PRODUCTION PROMOTION"
echo " Gate Rule: Unlocks Only After Staging Smoke Test & Receipt Chain Exit 0"
echo "--------------------------------------------------------------------------------"
read -r -p "Jenkins Approval Gate — Enter Audit Reason to Promote to Production: " REASON
REASON="${REASON:-Staging smoke test and serverless receipt chain verified healthy}"
echo "[JENKINS AUDIT LOG] Approved by: Ray | Reason: ${REASON}"
echo ""
run_cmd "./scripts/smoke-test.sh default production 13002"

next_stage
echo "--------------------------------------------------------------------------------"
echo " [STAGE 5/6] INTELLIGENCE LAYER: Deliberate Fault Injection & Prometheus Alert"
echo " Rule: KkPaymentsHighErrorRate fires when kk_payments_errors_total >= 3 in 1m"
echo "--------------------------------------------------------------------------------"
kubectl port-forward svc/kk-payments-service -n kijani-staging 13001:3001 >/tmp/pf-demo.log 2>&1 &
PF_PID=$!
trap 'kill ${PF_PID} 2>/dev/null || true' EXIT
sleep 2

run_cmd "curl -s -X POST http://127.0.0.1:13001/simulate-fault -H 'Content-Type: application/json' -d '{\"enable\": true}' && echo ''"
echo ""
run_cmd "curl -i -s http://127.0.0.1:13001/health | head -n 8"
echo ""
run_cmd "curl -s http://127.0.0.1:13001/metrics | grep -E 'kk_payments_errors_total|kk_payments_requests_total'"
echo ""
run_cmd "cat prometheus/alert-rules.yml | head -n 15"
echo ""
echo "--- Restoring Healthy Service State ---"
run_cmd "curl -s -X POST http://127.0.0.1:13001/simulate-fault -H 'Content-Type: application/json' -d '{\"enable\": false}' && echo ''"
run_cmd "curl -s http://127.0.0.1:13001/health && echo ''"

next_stage
echo "--------------------------------------------------------------------------------"
echo " [STAGE 6/6] GOVERNANCE, PEER FEEDBACK DIFF & VERSION CONTROL HYGIENE"
echo "--------------------------------------------------------------------------------"
run_cmd "git show 0c90678 --stat"
echo ""
run_cmd "git log --format='%ad %h %s' --date=short -n 15"

echo ""
echo "================================================================================"
echo " END-TO-END VERIFICATION COMPLETE — ALL LAYERS HEALTHY"
echo "================================================================================"
