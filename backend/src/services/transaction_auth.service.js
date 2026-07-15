const { Prisma } = require('../generated/prisma');
const AppError = require('../utils/appError');
const repository = require('../repositories/transactionAuth.repository');
const twilioService = require('./twilio.service');
const walletService = require('./wallet.service');
const notificationService = require('./notification.service');

const SESSION_TTL_MINUTES = 10;
const OTP_TTL_MINUTES = 5;
const MAX_OTP_ATTEMPTS = 5;

function maskPhoneNumber(phoneNumber) {
  if (!phoneNumber || phoneNumber.length < 4) return phoneNumber;
  const last4 = phoneNumber.slice(-4);
  return `${phoneNumber.slice(0, phoneNumber.length - 4).replace(/\d/g, '*')}${last4}`;
}

async function setPhoneNumber({ userId, phoneNumber }) {
  if (!/^\+[1-9]\d{7,14}$/.test(phoneNumber)) {
    throw new AppError(400, 'INVALID_PHONE_NUMBER', 'Enter a phone number in international format, e.g. +919876543210.');
  }
  await repository.setPhoneNumber(userId, phoneNumber);
  return { phoneNumber: maskPhoneNumber(phoneNumber) };
}

// The first step of the Transaction Authentication flow — records intent
// (which wallet, how much) before the user ever touches the fingerprint
// sensor, so the rest of the flow has a durable, server-verifiable anchor.
async function startSession({ userId, deviceId, purposeWalletId, amount }, ipAddress) {
  const amountDecimal = new Prisma.Decimal(amount);
  if (amountDecimal.lessThanOrEqualTo(0)) {
    throw new AppError(400, 'INVALID_AMOUNT', 'Amount must be greater than zero.');
  }

  // Reuses the Wallet module's own ownership check — throws
  // PURPOSE_WALLET_NOT_FOUND if this user doesn't own it, and never touches
  // wallet.service.js itself.
  const wallet = await walletService.getPurposeWallet(userId, purposeWalletId);
  if (wallet.status !== 'ACTIVE') {
    throw new AppError(400, 'WALLET_ARCHIVED', 'Cannot use an archived wallet.');
  }

  const expiresAt = new Date(Date.now() + SESSION_TTL_MINUTES * 60 * 1000);
  const session = await repository.createSession({ userId, deviceId, purposeWalletId, amount: amountDecimal, expiresAt });

  await repository.writeAuditLog(userId, 'TXN_AUTH_STARTED', { sessionId: session.id, purposeWalletId, amount }, ipAddress);

  return { sessionId: session.id, expiresAt: session.expiresAt };
}

async function loadOwnedSession(userId, sessionId) {
  const session = await repository.findSessionForUser(userId, sessionId);
  if (!session) {
    throw new AppError(404, 'SESSION_NOT_FOUND', 'Transaction authentication session not found.');
  }
  if (session.expiresAt < new Date() && !['EXPIRED', 'CANCELLED', 'COMPLETED'].includes(session.status)) {
    await repository.transitionStatus(sessionId, session.status, 'EXPIRED');
    throw new AppError(410, 'SESSION_EXPIRED', 'This transaction authentication session has expired. Please start again.');
  }
  return session;
}

// The fingerprint check itself happens on-device (existing BiometricService,
// unchanged) — this call records that it succeeded, gated behind a session
// that only exists because /start already verified wallet ownership for
// this authenticated user. Local fingerprint failures never reach the
// backend at all; the app cancels client-side after 3 failed attempts.
async function confirmFingerprint({ userId, sessionId }, ipAddress) {
  const session = await loadOwnedSession(userId, sessionId);
  if (session.status !== 'PENDING_FINGERPRINT') {
    throw new AppError(409, 'INVALID_SESSION_STATE', 'This step has already been completed for this session.');
  }

  const advanced = await repository.transitionStatus(sessionId, 'PENDING_FINGERPRINT', 'FINGERPRINT_CONFIRMED', {
    fingerprintConfirmedAt: new Date(),
  });
  if (!advanced) {
    throw new AppError(409, 'INVALID_SESSION_STATE', 'This step has already been completed for this session.');
  }

  await repository.writeAuditLog(userId, 'TXN_AUTH_FINGERPRINT_CONFIRMED', { sessionId }, ipAddress);
  return { sessionId };
}

// The fingerprint prompt itself and its retry counting (max 3 attempts) are
// entirely client-side (existing BiometricService, unchanged) — this is a
// write-only telemetry call so failures still show up in the Analytics
// events this phase requires, without giving the backend any say over the
// local retry loop.
async function recordFingerprintFailure({ userId, sessionId, attemptNumber }, ipAddress) {
  const session = await loadOwnedSession(userId, sessionId);
  await repository.writeAuditLog(userId, 'TXN_AUTH_FINGERPRINT_FAILED', { sessionId, attemptNumber }, ipAddress);

  if (attemptNumber >= 3 && session.status === 'PENDING_FINGERPRINT') {
    await repository.transitionStatus(sessionId, 'PENDING_FINGERPRINT', 'CANCELLED');
    await repository.writeAuditLog(userId, 'TXN_AUTH_FAILED', { sessionId, reason: 'fingerprint_exhausted' }, ipAddress);
  }
}

async function sendOtp({ userId, sessionId }, ipAddress) {
  const session = await loadOwnedSession(userId, sessionId);
  if (session.status !== 'FINGERPRINT_CONFIRMED') {
    throw new AppError(409, 'FINGERPRINT_NOT_CONFIRMED', 'Fingerprint confirmation is required before requesting an OTP.');
  }

  const user = await repository.findUserById(userId);
  if (!user.phoneNumber) {
    throw new AppError(400, 'PHONE_NUMBER_REQUIRED', 'Add a phone number to your profile before making a transfer.');
  }

  await twilioService.sendOtp(user.phoneNumber);

  await repository.transitionStatus(sessionId, 'FINGERPRINT_CONFIRMED', 'OTP_SENT', { otpSentAt: new Date() });
  await repository.writeAuditLog(userId, 'TXN_AUTH_OTP_SENT', { sessionId }, ipAddress);

  return { sessionId, maskedPhoneNumber: maskPhoneNumber(user.phoneNumber) };
}

async function verifyOtp({ userId, sessionId, code }, ipAddress) {
  const session = await loadOwnedSession(userId, sessionId);
  if (session.status !== 'OTP_SENT') {
    throw new AppError(409, 'OTP_NOT_SENT', 'Request an OTP before attempting to verify one.');
  }

  const otpAgeMinutes = (Date.now() - new Date(session.otpSentAt).getTime()) / 60000;
  if (otpAgeMinutes > OTP_TTL_MINUTES) {
    await repository.transitionStatus(sessionId, 'OTP_SENT', 'EXPIRED');
    await repository.writeAuditLog(userId, 'TXN_AUTH_OTP_EXPIRED', { sessionId }, ipAddress);
    throw new AppError(410, 'OTP_EXPIRED', 'This OTP has expired. Please request a new one.');
  }

  if (session.otpAttempts >= MAX_OTP_ATTEMPTS) {
    await repository.transitionStatus(sessionId, 'OTP_SENT', 'CANCELLED');
    await repository.writeAuditLog(userId, 'TXN_AUTH_OTP_FAILED', { sessionId, reason: 'max_attempts' }, ipAddress);
    throw new AppError(429, 'OTP_MAX_ATTEMPTS', 'Too many incorrect attempts. Please request a new OTP.');
  }

  const user = await repository.findUserById(userId);
  const approved = await twilioService.checkOtp(user.phoneNumber, code);

  if (!approved) {
    await repository.incrementOtpAttempts(sessionId);
    await repository.writeAuditLog(userId, 'TXN_AUTH_OTP_FAILED', { sessionId, reason: 'incorrect_code' }, ipAddress);
    throw new AppError(400, 'OTP_INCORRECT', 'Incorrect OTP. Please try again.');
  }

  await repository.transitionStatus(sessionId, 'OTP_SENT', 'OTP_VERIFIED', { otpVerifiedAt: new Date() });
  await repository.writeAuditLog(userId, 'TXN_AUTH_OTP_VERIFIED', { sessionId }, ipAddress);

  return { sessionId };
}

// Called by the Wallet Transfer route's guard middleware, never directly by
// the client. Atomically "claims" the session (OTP_VERIFIED -> COMPLETED) so
// it can only ever authorize one transfer — a second attempt to reuse the
// same sessionId fails the atomic transition and is rejected.
async function claimVerifiedSession({ userId, sessionId, purposeWalletId, amount }) {
  const session = await loadOwnedSession(userId, sessionId);

  if (session.status !== 'OTP_VERIFIED') {
    throw new AppError(403, 'TRANSACTION_AUTH_REQUIRED', 'Complete fingerprint and OTP verification before transferring.');
  }
  if (session.purposeWalletId !== purposeWalletId || !session.amount.equals(new Prisma.Decimal(amount))) {
    throw new AppError(400, 'SESSION_MISMATCH', 'This authorization does not match the requested transfer.');
  }

  const claimed = await repository.transitionStatus(sessionId, 'OTP_VERIFIED', 'COMPLETED', { completedAt: new Date() });
  if (!claimed) {
    throw new AppError(409, 'SESSION_ALREADY_USED', 'This authorization has already been used.');
  }

  return session;
}

// Called from the transfer-guard middleware's response `finish` handler —
// after wallet.controller.js has already run and responded. Writes the
// required audit trail (user, device, time, amount, wallet, transaction id)
// and, on success, sends the "Transfer Successful" push via the existing
// notification service (unchanged, just newly wired to Firebase for real).
async function recordTransferOutcome({ userId, deviceId, sessionId, purposeWalletId, amount, transactionId, success }, ipAddress) {
  const metadata = { sessionId, deviceId, purposeWalletId, amount, transactionId };

  if (!success) {
    await repository.writeAuditLog(userId, 'TXN_AUTH_TRANSFER_FAILURE', metadata, ipAddress);
    return;
  }

  await repository.writeAuditLog(userId, 'TXN_AUTH_TRANSFER_SUCCESS', metadata, ipAddress);

  try {
    const wallet = await walletService.getPurposeWallet(userId, purposeWalletId);
    await notificationService.sendPushNotification(userId, {
      title: 'Transfer Successful',
      body: `₹${amount} transferred from Main Wallet to ${wallet.name}.`,
      data: { type: 'TRANSFER_SUCCESS', transactionId: transactionId ?? '', purposeWalletId },
    });
  } catch (err) {
    // Best-effort — a notification failure must never surface as a transfer
    // failure to the user; the transfer itself already succeeded.
    console.error('[TransactionAuthService] Failed to send transfer notification:', err.message);
  }
}

module.exports = {
  setPhoneNumber,
  startSession,
  confirmFingerprint,
  recordFingerprintFailure,
  sendOtp,
  verifyOtp,
  claimVerifiedSession,
  recordTransferOutcome,
};
