const fs = require('fs');
const path = require('path');

module.exports.receiptGenerator = async (receiptPayload) => {
  const enriched = {
    ...receiptPayload,
    chainStage1: 'kk-receipt-generator',
    receiptNumber: `KK-${receiptPayload.receiptId.toUpperCase()}`,
    generatedAt: new Date().toISOString()
  };
  console.log(JSON.stringify({
    service: 'kk-receipt-generator',
    event: 's3_object_created_triggered',
    bucket: receiptPayload.bucket,
    receiptId: receiptPayload.receiptId
  }));
  return enriched;
};

module.exports.fraudValidator = async (enrichedReceipt) => {
  const riskScore = enrichedReceipt.amount > 100000 ? 'REVIEW' : 'CLEARED';
  const validated = {
    ...enrichedReceipt,
    chainStage2: 'kk-fraud-validator',
    fraudStatus: riskScore,
    validatedAt: new Date().toISOString()
  };
  console.log(JSON.stringify({
    service: 'kk-fraud-validator',
    event: 'receipt_validated',
    receiptId: enrichedReceipt.receiptId,
    fraudStatus: riskScore
  }));
  return validated;
};

module.exports.customerNotifier = async (validatedReceipt, outputDir) => {
  const finalRecord = {
    ...validatedReceipt,
    chainStage3: 'kk-notifier',
    notificationStatus: 'DISPATCHED',
    dispatchedAt: new Date().toISOString()
  };
  fs.mkdirSync(outputDir, { recursive: true });
  const outPath = path.join(outputDir, `${validatedReceipt.receiptId}-notified.json`);
  fs.writeFileSync(outPath, JSON.stringify(finalRecord, null, 2));

  console.log(JSON.stringify({
    service: 'kk-notifier',
    event: 'receipt_chain_completed',
    receiptId: validatedReceipt.receiptId,
    outputFile: outPath
  }));
  return finalRecord;
};
