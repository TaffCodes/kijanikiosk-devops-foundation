#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:-kijani-staging}"
EXPECTED_ENV="${2:-staging}"
LOCAL_PORT="${3:-13001}"

echo "=== [SMOKE TEST] Starting verification for kk-payments in namespace: ${NAMESPACE} ==="

kubectl rollout status deployment/kk-payments -n "${NAMESPACE}" --timeout=90s

kubectl port-forward svc/kk-payments-service -n "${NAMESPACE}" "${LOCAL_PORT}:3001" >/tmp/pf-${NAMESPACE}.log 2>&1 &
PF_PID=$!
trap 'kill ${PF_PID} 2>/dev/null || true' EXIT
sleep 3

echo "1. Checking /health endpoint and ConfigMap isolation..."
HEALTH_JSON=$(curl -sf "http://127.0.0.1:${LOCAL_PORT}/health")
echo "   Health Response: ${HEALTH_JSON}"

echo "${HEALTH_JSON}" | grep -q "\"environment\":\"${EXPECTED_ENV}\""
if [[ "${EXPECTED_ENV}" == "staging" ]]; then
  echo "${HEALTH_JSON}" | grep -q "postgres-staging.kijani-staging.svc.cluster.local"
  echo "   [PASS] Staging DB_HOST isolation verified."
else
  echo "${HEALTH_JSON}" | grep -q "postgres-prod.default.svc.cluster.local"
  echo "   [PASS] Production DB_HOST isolation verified."
fi

echo "2. Triggering payment transaction to verify serverless receipt chain..."
PAY_JSON=$(curl -sf -X POST "http://127.0.0.1:${LOCAL_PORT}/pay" \
  -H "Content-Type: application/json" \
  -d '{"amount": 4500, "customer": "nia@kijanikiosk.co.ke"}')
echo "   Payment Response: ${PAY_JSON}"

RECEIPT_ID=$(echo "${PAY_JSON}" | sed -E 's/.*"receiptId":"([^"]+)".*/\1/')
sleep 2

BUCKET_NAME="kk-payments-receipts-${EXPECTED_ENV}"
RAW_RECEIPT="/var/lib/kijanikiosk/s3/${BUCKET_NAME}/${RECEIPT_ID}.json"
PROCESSED_RECEIPT="/var/lib/kijanikiosk/s3/${BUCKET_NAME}-processed/${RECEIPT_ID}-notified.json"

if [[ -f "${RAW_RECEIPT}" && -f "${PROCESSED_RECEIPT}" ]]; then
  echo "   [PASS] Serverless receipt chain verified: ${PROCESSED_RECEIPT}"
else
  echo "   [FAIL] Receipt chain output missing!"
  exit 1
fi

echo "3. Verifying Prometheus /metrics exposure..."
curl -sf "http://127.0.0.1:${LOCAL_PORT}/metrics" | grep -q "kk_payments_requests_total"
echo "   [PASS] Prometheus metrics endpoint active."

echo "=== [SMOKE TEST PASSED] All checks succeeded for ${NAMESPACE} ==="
