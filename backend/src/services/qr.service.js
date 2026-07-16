const AppError = require('../utils/appError');
const repository = require('../repositories/qr.repository');
const merchantRepository = require('../repositories/merchant.repository');
const merchantService = require('./merchant.service');

// Dev-only, mirrors wallet.service.js's loadDemoMoney() NODE_ENV gate — this
// stands in for a real merchant terminal generating a fresh QR (a real one
// would regenerate periodically for the same replay-prevention reason).
async function generateDemo(merchantId) {
  if (process.env.NODE_ENV === 'production') {
    throw new AppError(403, 'DEMO_QR_DISABLED', 'Demo QR codes are not available in production.');
  }

  const merchant = await merchantRepository.findById(merchantId);
  if (!merchant) {
    throw new AppError(404, 'MERCHANT_NOT_FOUND', 'Merchant not found.');
  }
  if (merchant.status !== 'ACTIVE') {
    throw new AppError(400, 'MERCHANT_INACTIVE', 'This merchant is not available for payment.');
  }

  const qr = await repository.create(merchantId);
  const payload = JSON.stringify({ v: 1, type: 'SVP_MERCHANT_QR', qrId: qr.id, merchantCode: merchant.merchantCode });
  return { qrId: qr.id, payload, expiresAt: qr.expiresAt };
}

// Loads a QR and enforces every validity rule in one place — expired
// (lazily flipped here, same pattern as transaction_auth.service.js's
// loadOwnedSession), already used, or its merchant no longer active. Shared
// by validate() and pay() so a scan and a payment attempt are held to
// exactly the same standard.
async function loadValidQr(qrId) {
  const qr = await repository.findById(qrId);
  if (!qr) {
    throw new AppError(404, 'QR_NOT_FOUND', 'This QR code is not recognized.');
  }
  if (qr.status === 'ACTIVE' && qr.expiresAt < new Date()) {
    await repository.expire(qrId);
    throw new AppError(410, 'QR_EXPIRED', 'This QR code has expired.');
  }
  if (qr.status === 'EXPIRED') {
    throw new AppError(410, 'QR_EXPIRED', 'This QR code has expired.');
  }
  if (qr.status === 'USED') {
    throw new AppError(409, 'QR_ALREADY_USED', 'This QR code has already been used.');
  }
  if (qr.merchant.status !== 'ACTIVE') {
    throw new AppError(400, 'MERCHANT_INACTIVE', 'This merchant is not available for payment.');
  }
  return qr;
}

// Read-only — scanning a QR never consumes it. Only POST /qr/:qrId/pay does.
async function validate(qrId) {
  const qr = await loadValidQr(qrId);
  return {
    qrId: qr.id,
    expiresAt: qr.expiresAt,
    merchant: merchantService.toPublicMerchant(qr.merchant),
  };
}

// Called only after requirePaymentPin has already verified the caller's
// Payment PIN — never directly reachable without it, exactly like
// merchant.service.js's own pay().
async function pay(userId, { qrId, purposeWalletId, amount }, ipAddress) {
  const qr = await loadValidQr(qrId);

  // Atomic compare-and-swap ACTIVE -> USED — the single operation that
  // prevents replay attacks and duplicate payments. A concurrent or repeat
  // call for the same qrId can never pass this twice.
  const consumed = await repository.consume(qrId);
  if (!consumed) {
    throw new AppError(409, 'QR_ALREADY_USED', 'This QR code has already been used.');
  }

  try {
    // merchantId comes from the QR record itself, never from the request
    // body — a client can never redirect a scanned QR's payment to a
    // different merchant. Delegates to the existing, unmodified
    // merchantService.pay() for the actual money movement.
    const payment = await merchantService.pay(userId, { merchantId: qr.merchantId, purposeWalletId, amount }, ipAddress);
    await repository.linkPayment(qrId, payment.id);
    await repository.writeAuditLog(
      userId,
      'QR_PAYMENT_SUCCESS',
      { qrId, paymentId: payment.id, merchantId: qr.merchantId, purposeWalletId, amount },
      ipAddress,
    );
    return payment;
  } catch (err) {
    // The payment failed after the QR was already consumed (e.g.
    // insufficient balance) — release it so the same scan can be retried
    // instead of permanently burning it on one failed attempt.
    await repository.release(qrId);
    await repository.writeAuditLog(
      userId,
      'QR_PAYMENT_FAILURE',
      { qrId, merchantId: qr.merchantId, purposeWalletId, amount, reason: err.code },
      ipAddress,
    );
    throw err;
  }
}

module.exports = { generateDemo, validate, pay };
