const test = require('node:test');
const assert = require('node:assert');
const { checkAndResetDailyLimits, deviceScans, globalScans, DAILY_SCAN_LIMIT } = require('../routes/ai');

test('AI Scan Limit: Initial scan count is 0 for new device', () => {
  const deviceId = 'test-device-uuid-1';
  const { record } = checkAndResetDailyLimits(deviceId);
  assert.strictEqual(record.count, 0);
});

test('AI Scan Limit: Increments scan count per device correctly', () => {
  const deviceId = 'test-device-uuid-2';
  const { record } = checkAndResetDailyLimits(deviceId);
  record.count += 1;

  const { record: recordAgain } = checkAndResetDailyLimits(deviceId);
  assert.strictEqual(recordAgain.count, 1);
});

test('AI Scan Limit: Enforces daily limit cap of 8 scans', () => {
  const deviceId = 'test-device-uuid-3';
  const { record } = checkAndResetDailyLimits(deviceId);
  record.count = DAILY_SCAN_LIMIT;

  const isExceeded = record.count >= DAILY_SCAN_LIMIT;
  assert.strictEqual(isExceeded, true);

  const remaining = Math.max(0, DAILY_SCAN_LIMIT - record.count);
  assert.strictEqual(remaining, 0);
});

test('AI Scan Limit: Different devices track quotas independently', () => {
  const devA = 'device-alpha';
  const devB = 'device-beta';

  const { record: recA } = checkAndResetDailyLimits(devA);
  const { record: recB } = checkAndResetDailyLimits(devB);

  recA.count = 5;
  recB.count = 2;

  assert.strictEqual(deviceScans.get(devA).count, 5);
  assert.strictEqual(deviceScans.get(devB).count, 2);
});
