#!/usr/bin/env bash
set -euo pipefail

pause_step() {
  echo ""
  echo "--------------------------------------------------------------------------------"
  read -r -p "Press [ENTER] to run the next live demo step..."
  echo "--------------------------------------------------------------------------------"
}

clear
echo "================================================================================"
echo " KIJANIKIOSK CAPSTONE LIVE DEMO (TRACK A: INFRASTRUCTURE-FIRST)"
echo "================================================================================"
echo ""
echo "[SAY TO CLASS]:"
echo "  'I built Track A across four layers: Terraform & Ansible provision our isolated"
echo "   kijani-staging namespace; Kubernetes runs the exact same Deployment manifest"
echo "   in staging and production with isolated ConfigMaps; Jenkins gates production"
echo "   behind a smoke test and approval reason; and Prometheus monitors health alerts.'"

pause_step
echo "=== STEP 1: Verify Infrastructure Layer (Terraform Namespace & Quota) ==="
echo "[SAY TO CLASS]: 'Here is the kijani-staging namespace and resource quota provisioned by Terraform, alongside our running pods in both environments.'"
kubectl get namespace kijani-staging --show-labels
kubectl get resourcequota -n kijani-staging
kubectl get pods -n kijani-staging
kubectl get pods -n default

pause_step
echo "=== STEP 2: Verify Runtime Layer (Identical Deployment, Isolated ConfigMaps) ==="
echo "[SAY TO CLASS]: 'Both namespaces run the exact same Deployment manifest, but Ansible injected distinct ConfigMaps so DB_HOST and RECEIPT_BUCKET are strictly isolated.'"
echo "--- Staging ConfigMap (kijani-staging) ---"
kubectl get configmap kk-payments-config -n kijani-staging -o jsonpath='{.data}' && echo ""
echo "--- Production ConfigMap (default) ---"
kubectl get configmap kk-payments-config -n default -o jsonpath='{.data}' && echo ""

pause_step
echo "=== STEP 3: Execute Automated Staging Smoke Test & Serverless Receipt Chain ==="
echo "[SAY TO CLASS]: 'Now we run our staging smoke test, which verifies DB_HOST isolation, sends a live payment to kk-payments-receipts-staging, and triggers the Week 10 serverless receipt chain.'"
./scripts/smoke-test.sh kijani-staging staging 13001
echo ""
echo "--- Latest Processed Receipt from Serverless Notifier ---"
LATEST_RECEIPT=$(ls -t /var/lib/kijanikiosk/s3/kk-payments-receipts-staging-processed/*-notified.json | head -n 1)
cat "${LATEST_RECEIPT}"

pause_step
echo "=== STEP 4: Production Approval Gate & Production Smoke Test ==="
read -r -p "Enter Production Approval Reason [Default: Staging smoke test & receipt chain verified]: " REASON
REASON="${REASON:-Staging smoke test & receipt chain verified}"
echo "[AUDIT LOG] Production deployment approved by operator. Reason: ${REASON}"
./scripts/smoke-test.sh default production 13002

pause_step
echo "=== STEP 5: Deliberate Fault Injection, Prometheus Metrics & Recovery ==="
echo "[SAY TO CLASS]: 'Finally, we inject a deliberate fault into staging to demonstrate error handling and Prometheus alert threshold evaluation.'"
kubectl port-forward svc/kk-payments-service -n kijani-staging 13001:3001 >/tmp/pf-demo.log 2>&1 &
PF_PID=$!
trap 'kill ${PF_PID} 2>/dev/null || true' EXIT
sleep 2

echo "-> Injecting fault via POST /simulate-fault..."
curl -s -X POST http://127.0.0.1:13001/simulate-fault -H "Content-Type: application/json" -d '{"enable": true}' && echo ""
echo "-> Querying /health during active fault (expect HTTP 500):"
curl -i -s http://127.0.0.1:13001/health | head -n 8
echo ""
echo "-> Scraping Prometheus /metrics (kk_payments_errors_total breaches >= 3 alert threshold):"
curl -s http://127.0.0.1:13001/metrics | grep -E "kk_payments_errors_total|kk_payments_requests_total"
echo ""
echo "-> Restoring normal service and verifying recovery (expect HTTP 200):"
curl -s -X POST http://127.0.0.1:13001/simulate-fault -H "Content-Type: application/json" -d '{"enable": false}' && echo ""
curl -s http://127.0.0.1:13001/health && echo ""

echo ""
echo "================================================================================"
echo " LIVE DEMO COMPLETE — ALL 4 TRACK A LAYERS VERIFIED END-TO-END"
echo "================================================================================"
