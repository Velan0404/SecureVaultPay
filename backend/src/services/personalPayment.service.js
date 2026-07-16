const { Prisma } = require('../generated/prisma');
const AppError = require('../utils/appError');
const repository = require('../repositories/personalPayment.repository');
const walletService = require('./wallet.service');
const notificationService = require('./notification.service');

function maskPhoneNumber(phoneNumber) {
  if (!phoneNumber || phoneNumber.length < 4) return phoneNumber;
  const last4 = phoneNumber.slice(-4);
  return `${phoneNumber.slice(0, phoneNumber.length - 4).replace(/\d/g, '*')}${last4}`;
}

async function getMyQr(userId) {
  const secureVaultId = await repository.getOrCreateSecureVaultId(userId);
  const user = await repository.findUserById(userId);
  const payload = JSON.stringify({ v: 1, type: 'USER_PAYMENT', userId, secureVaultId });
  return {
    payload,
    userId,
    secureVaultId,
    fullName: user.fullName,
    phoneNumber: user.phoneNumber,
  };
}

// Read-only — Personal QR is a permanent identity code, not a one-time
// token, so unlike Merchant QR there is no consume/expire state here.
// Scanning (and re-scanning, forever) never mutates anything; only pay()
// below does.
async function lookupReceiver({ userId, secureVaultId }) {
  const user = await repository.findUserById(userId);
  if (!user) {
    throw new AppError(404, 'RECEIVER_NOT_FOUND', 'This SecureVault Pay user could not be found.');
  }
  // If the scanned payload carried a secureVaultId, it must match what's on
  // record for this userId — catches a manually tampered payload pairing a
  // real userId with the wrong id.
  if (secureVaultId && user.secureVaultId && secureVaultId !== user.secureVaultId) {
    throw new AppError(400, 'INVALID_QR', 'This QR code is not valid.');
  }
  if (!user.isActive) {
    throw new AppError(400, 'RECEIVER_INACTIVE', 'This account is not able to receive payments.');
  }

  return {
    userId: user.id,
    fullName: user.fullName,
    maskedPhoneNumber: user.phoneNumber ? maskPhoneNumber(user.phoneNumber) : null,
  };
}

// Phase 7.1 — Search User by mobile number (Dashboard "Pay" -> Person). The
// same public shape as lookupReceiver, plus secureVaultId/profileImage per
// this phase's spec. Deliberately does NOT expose password/PIN/email/wallet
// balance — only what a receiver needs to be identified before paying them.
async function searchByPhone(phoneNumber) {
  const user = await repository.findUserByPhoneNumber(phoneNumber);
  if (!user || !user.isActive) {
    throw new AppError(404, 'RECEIVER_NOT_FOUND', 'No SecureVault Pay account found.');
  }

  const secureVaultId = await repository.getOrCreateSecureVaultId(user.id);
  return {
    userId: user.id,
    fullName: user.fullName,
    maskedPhoneNumber: maskPhoneNumber(user.phoneNumber),
    secureVaultId,
    // No profile-image storage exists yet anywhere in this app — always
    // null rather than fabricating one, honoring the "if available" wording.
    profileImage: null,
  };
}

// Called only after requirePaymentPin (paymentPin.middleware.js) has already
// verified the caller's Payment PIN — never directly reachable without it.
async function pay(senderId, { receiverId, purposeWalletId, amount, note }, ipAddress) {
  if (senderId === receiverId) {
    throw new AppError(400, 'SELF_PAYMENT_NOT_ALLOWED', 'You cannot send money to yourself.');
  }

  const amountDecimal = new Prisma.Decimal(amount);
  if (amountDecimal.lessThanOrEqualTo(0)) {
    throw new AppError(400, 'INVALID_AMOUNT', 'Amount must be greater than zero.');
  }

  const receiver = await repository.findUserById(receiverId);
  if (!receiver) {
    throw new AppError(404, 'RECEIVER_NOT_FOUND', 'This SecureVault Pay user could not be found.');
  }
  if (!receiver.isActive) {
    throw new AppError(400, 'RECEIVER_INACTIVE', 'This account is not able to receive payments.');
  }

  const sender = await repository.findUserById(senderId);

  // Reuses the Wallet module's own ownership + active-status check — Main
  // Wallet is never a valid source here since this only ever accepts a
  // Purpose Wallet id, and wallet.service.js is never modified by this call.
  const wallet = await walletService.getPurposeWallet(senderId, purposeWalletId);
  if (wallet.status !== 'ACTIVE') {
    throw new AppError(400, 'WALLET_ARCHIVED', 'Cannot pay from an archived wallet.');
  }

  // Reuses the Wallet module's own lazy-provisioning — a receiver who has
  // never opened the app still gets a Main Wallet row to credit into, same
  // as every other place that credits a Main Wallet (e.g. loadDemoMoney).
  const receiverMainWallet = await walletService.getMainWallet(receiverId);

  const result = await repository.executePayment({
    senderId,
    receiverId,
    purposeWalletId,
    purposeWalletName: wallet.name,
    receiverMainWalletId: receiverMainWallet.id,
    senderName: sender.fullName,
    receiverName: receiver.fullName,
    amount: amountDecimal,
    note,
  });

  if (!result.success) {
    throw new AppError(400, 'INSUFFICIENT_BALANCE', 'Purpose wallet balance is insufficient for this payment.');
  }

  await repository.writeAuditLog(
    senderId,
    'PERSONAL_PAYMENT_SENT',
    { paymentId: result.payment.id, receiverId, purposeWalletId, amount: result.payment.amount },
    ipAddress,
  );

  try {
    await notificationService.sendPushNotification(senderId, {
      title: 'Payment Sent',
      body: `₹${amount} sent to ${receiver.fullName}.`,
      data: { type: 'PERSONAL_PAYMENT_SENT', paymentId: result.payment.id, receiverId },
    });
    await notificationService.sendPushNotification(receiverId, {
      title: 'Payment Received',
      body: `₹${amount} received from ${sender.fullName}.`,
      data: { type: 'PERSONAL_PAYMENT_RECEIVED', paymentId: result.payment.id, senderId },
    });
  } catch (err) {
    // Best-effort — a notification failure must never surface as a payment
    // failure to the user; the payment itself already succeeded.
    console.error('[PersonalPaymentService] Failed to send payment notification:', err.message);
  }

  return {
    id: result.payment.id,
    receiverId,
    receiverName: receiver.fullName,
    purposeWalletId,
    amount: result.payment.amount,
    note: result.payment.note,
    createdAt: result.payment.createdAt,
  };
}

module.exports = { getMyQr, lookupReceiver, searchByPhone, pay };
