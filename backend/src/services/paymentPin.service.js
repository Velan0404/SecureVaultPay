const AppError = require('../utils/appError');
const { hashPassword, comparePassword } = require('../utils/password.util');
const repository = require('../repositories/paymentPin.repository');

async function hasPaymentPin(userId) {
  const record = await repository.findByUserId(userId);
  return record !== null;
}

// Payment PIN is created exactly once ("only created once, never asked
// again unless reset") — a second attempt is rejected rather than silently
// overwriting a PIN the user didn't intend to replace. There is no reset
// flow in this phase.
async function createPaymentPin({ userId, pin }) {
  const existing = await repository.findByUserId(userId);
  if (existing) {
    throw new AppError(409, 'PAYMENT_PIN_ALREADY_SET', 'A Payment PIN has already been created for this account.');
  }
  const pinHash = await hashPassword(pin);
  await repository.create(userId, pinHash);
}

// The single choke point for authorizing a merchant payment — verified
// server-side against the stored hash every time, never against a
// client-cached copy (unlike the App PIN's routine unlock, which is
// deliberately local-only since it only gates local app access rather than
// money movement).
async function verifyPaymentPin({ userId, pin }) {
  const record = await repository.findByUserId(userId);
  if (!record || !(await comparePassword(pin, record.pinHash))) {
    throw new AppError(401, 'INVALID_PAYMENT_PIN', 'Incorrect Payment PIN.');
  }
}

module.exports = { hasPaymentPin, createPaymentPin, verifyPaymentPin };
