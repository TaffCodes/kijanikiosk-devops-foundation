const fs = require('fs');
const path = require('path');
const { receiptGenerator, fraudValidator, customerNotifier } = require('./handler');

async function executeChain() {
  const receiptFile = process.argv[2];
  if (!receiptFile || !fs.existsSync(receiptFile)) {
    console.error('Receipt file path required to trigger serverless chain');
    process.exit(1);
  }
  const raw = JSON.parse(fs.readFileSync(receiptFile, 'utf8'));
  const bucketDir = path.dirname(receiptFile);
  const processedDir = `${bucketDir}-processed`;

  const step1 = await receiptGenerator(raw);
  const step2 = await fraudValidator(step1);
  await customerNotifier(step2, processedDir);
}

executeChain().catch((err) => {
  console.error(err);
  process.exit(1);
});
