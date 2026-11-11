const express = require('express');
const fs = require('fs');
const path = require('path');
const { execFile } = require('child_process');

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3001;
const APP_ENV = process.env.APP_ENV || 'staging';
const DB_HOST = process.env.DB_HOST || 'postgres-staging.kijani-staging.svc.cluster.local';
const RECEIPT_BUCKET = process.env.RECEIPT_BUCKET || 'kk-payments-receipts-staging';
const S3_BASE_DIR = process.env.S3_BASE_DIR || '/var/lib/kijanikiosk/s3';
const APP_VERSION = process.env.npm_package_version || '1.0.0';

let totalRequests = 0;
let paymentRequests = 0;
let paymentErrors = 0;
let faultMode = false;
let lastLatencyMs = 12;

function logStructured(level, event, details = {}) {
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    level,
    service: 'kk-payments',
    environment: APP_ENV,
    version: APP_VERSION,
    dbHost: DB_HOST,
    receiptBucket: RECEIPT_BUCKET,
    event,
    ...details
  }));
}

app.get('/health', (req, res) => {
  totalRequests++;
  if (faultMode) {
    paymentErrors++;
    logStructured('ERROR', 'health_check_failed', { reason: 'deliberate_fault_active' });
    return res.status(500).json({
      status: 'error',
      environment: APP_ENV,
      version: APP_VERSION,
      dbHost: DB_HOST,
      receiptBucket: RECEIPT_BUCKET,
      faultMode: true
    });
  }
  res.status(200).json({
    status: 'ok',
    environment: APP_ENV,
    version: APP_VERSION,
    dbHost: DB_HOST,
    receiptBucket: RECEIPT_BUCKET,
    faultMode: false
  });
});

app.post('/pay', (req, res) => {
  const start = Date.now();
  totalRequests++;
  paymentRequests++;

  if (faultMode || req.body.forceError) {
    paymentErrors++;
    lastLatencyMs = Date.now() - start;
    logStructured('ERROR', 'payment_failed', { reason: 'simulated_gateway_fault' });
    return res.status(500).json({ error: 'Payment processing fault', environment: APP_ENV });
  }

  const receiptId = `rcpt-${Date.now()}`;
  const amount = req.body.amount || 2500;
  const customer = req.body.customer || 'amina@kijanikiosk.co.ke';

  const receiptPayload = {
    receiptId,
    amount,
    currency: 'KES',
    customer,
    environment: APP_ENV,
    dbHost: DB_HOST,
    bucket: RECEIPT_BUCKET,
    timestamp: new Date().toISOString()
  };

  try {
    const bucketDir = path.join(S3_BASE_DIR, RECEIPT_BUCKET);
    fs.mkdirSync(bucketDir, { recursive: true });
    const receiptPath = path.join(bucketDir, `${receiptId}.json`);
    fs.writeFileSync(receiptPath, JSON.stringify(receiptPayload, null, 2));

    lastLatencyMs = Date.now() - start;
    logStructured('INFO', 'receipt_written_to_bucket', {
      receiptId,
      bucket: RECEIPT_BUCKET,
      path: receiptPath,
      latencyMs: lastLatencyMs
    });

    const chainScript = path.join(__dirname, '../serverless/run-receipt-chain.js');
    if (fs.existsSync(chainScript)) {
      execFile('node', [chainScript, receiptPath], (err, stdout) => {
        if (stdout) process.stdout.write(stdout);
      });
    }

    return res.status(201).json({
      status: 'payment_confirmed',
      receiptId,
      bucket: RECEIPT_BUCKET,
      dbHost: DB_HOST,
      environment: APP_ENV
    });
  } catch (err) {
    paymentErrors++;
    logStructured('ERROR', 'receipt_write_failed', { message: err.message });
    return res.status(500).json({ error: 'Failed to persist receipt', details: err.message });
  }
});

app.post('/simulate-fault', (req, res) => {
  faultMode = Boolean(req.body.enable);
  if (faultMode) {
    paymentErrors += 10;
  }
  logStructured('WARN', 'fault_mode_toggled', { faultMode });
  res.status(200).json({ status: 'updated', faultMode, paymentErrors });
});

app.get('/metrics', (req, res) => {
  res.set('Content-Type', 'text/plain; version=0.0.4');
  res.send([
    '# HELP kk_payments_requests_total Total HTTP requests processed by kk-payments',
    '# TYPE kk_payments_requests_total counter',
    `kk_payments_requests_total{environment="${APP_ENV}"} ${totalRequests}`,
    '# HELP kk_payments_transactions_total Total payment transactions attempted',
    '# TYPE kk_payments_transactions_total counter',
    `kk_payments_transactions_total{environment="${APP_ENV}"} ${paymentRequests}`,
    '# HELP kk_payments_errors_total Total failed payment or health requests',
    '# TYPE kk_payments_errors_total counter',
    `kk_payments_errors_total{environment="${APP_ENV}"} ${paymentErrors}`,
    '# HELP kk_payments_latency_ms Last recorded payment latency in milliseconds',
    '# TYPE kk_payments_latency_ms gauge',
    `kk_payments_latency_ms{environment="${APP_ENV}"} ${lastLatencyMs}`
  ].join('\n') + '\n');
});

app.listen(PORT, () => {
  logStructured('INFO', 'server_started', { port: PORT });
});
