const crypto = require('crypto');
const prisma = require('../config/prisma');

// Excludes visually ambiguous characters (0/O, 1/I) since this is meant to
// be read and typed by a human, unlike an internal uuid.
const SECURE_VAULT_ID_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

function generateSecureVaultId() {
  const bytes = crypto.randomBytes(8);
  let code = '';
  for (let i = 0; i < 8; i += 1) {
    code += SECURE_VAULT_ID_CHARS[bytes[i] % SECURE_VAULT_ID_CHARS.length];
  }
  return `SVP-${code}`;
}

async function findUserById(userId) {
  return prisma.user.findUnique({ where: { id: userId } });
}

// phoneNumber has no @unique constraint on User (unlike email), so this
// intentionally uses findFirst rather than findUnique — a demo dataset could
// in principle have a duplicate, and the first active match is good enough
// for search-by-phone, same tolerance the rest of this module already has.
async function findUserByPhoneNumber(phoneNumber) {
  return prisma.user.findFirst({ where: { phoneNumber } });
}

// Lazily generates + persists a secureVaultId the first time it's needed —
// same idiom as wallet.repository.js's getOrCreateMainWallet. Retries on the
// astronomically unlikely unique-collision case.
async function getOrCreateSecureVaultId(userId) {
  const user = await findUserById(userId);
  if (user.secureVaultId) return user.secureVaultId;

  for (let attempt = 0; attempt < 5; attempt += 1) {
    const candidate = generateSecureVaultId();
    try {
      const updated = await prisma.user.update({
        where: { id: userId },
        data: { secureVaultId: candidate },
      });
      return updated.secureVaultId;
    } catch (err) {
      if (err.code === 'P2002') continue; // collision — retry with a new candidate
      throw err;
    }
  }
  throw new Error('Failed to generate a unique SecureVault ID after 5 attempts.');
}

// Atomically debits the sender's Purpose Wallet AND credits the receiver's
// Main Wallet in ONE transaction — unlike Merchant QR, Personal Payment
// never delegates to another module's own $transaction, so there's no
// consume/release compromise needed here.
async function executePayment({
  senderId,
  receiverId,
  purposeWalletId,
  purposeWalletName,
  receiverMainWalletId,
  senderName,
  receiverName,
  amount,
  note,
}) {
  return prisma.$transaction(async (tx) => {
    const debited = await tx.purposeWallet.updateMany({
      where: { id: purposeWalletId, balance: { gte: amount } },
      data: { balance: { decrement: amount } },
    });
    if (debited.count === 0) {
      return { success: false };
    }

    await tx.mainWallet.update({
      where: { id: receiverMainWalletId },
      data: { balance: { increment: amount } },
    });

    const payment = await tx.personalPayment.create({
      data: { senderId, receiverId, senderPurposeWalletId: purposeWalletId, amount, note, status: 'SUCCESS' },
    });

    await tx.walletTransaction.create({
      data: {
        userId: senderId,
        purposeWalletId,
        type: 'PERSONAL_PAYMENT_SENT',
        amount,
        source: purposeWalletName,
        destination: receiverName,
        description: note ? `Sent to ${receiverName} — ${note}` : `Sent to ${receiverName}`,
        status: 'SUCCESS',
      },
    });

    await tx.walletTransaction.create({
      data: {
        userId: receiverId,
        mainWalletId: receiverMainWalletId,
        type: 'PERSONAL_PAYMENT_RECEIVED',
        amount,
        source: senderName,
        destination: 'Main Wallet',
        description: note ? `Received from ${senderName} — ${note}` : `Received from ${senderName}`,
        status: 'SUCCESS',
      },
    });

    return { success: true, payment };
  });
}

async function writeAuditLog(userId, action, metadata, ipAddress) {
  await prisma.auditLog.create({ data: { userId, action, metadata, ipAddress } });
}

module.exports = { findUserById, findUserByPhoneNumber, getOrCreateSecureVaultId, executePayment, writeAuditLog };
