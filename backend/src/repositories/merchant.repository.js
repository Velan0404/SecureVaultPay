const prisma = require('../config/prisma');

async function listActive({ category } = {}) {
  return prisma.merchant.findMany({
    where: { status: 'ACTIVE', ...(category ? { merchantCategory: category } : {}) },
    orderBy: { merchantName: 'asc' },
  });
}

async function findById(id) {
  return prisma.merchant.findUnique({ where: { id } });
}

// Atomically debits the Purpose Wallet, records the MerchantPayment, and
// logs a WalletTransaction (type PURPOSE_PAYMENT — reserved for exactly this
// in the Wallet module's schema since Phase 4) — all in one transaction so a
// payment can never partially apply. transactionAuthSessionId stays null —
// merchant payments are authorized by Payment PIN (Phase 5.1), not a
// fingerprint/OTP session; the column is kept nullable for that older,
// now-unused path rather than migrated away.
async function executePayment({ userId, purposeWalletId, purposeWalletName, merchantId, merchantName, amount }) {
  return prisma.$transaction(async (tx) => {
    const debited = await tx.purposeWallet.updateMany({
      where: { id: purposeWalletId, balance: { gte: amount } },
      data: { balance: { decrement: amount } },
    });

    if (debited.count === 0) {
      return { success: false };
    }

    const payment = await tx.merchantPayment.create({
      data: {
        userId,
        purposeWalletId,
        merchantId,
        amount,
        status: 'SUCCESS',
      },
    });

    await tx.walletTransaction.create({
      data: {
        userId,
        purposeWalletId,
        type: 'PURPOSE_PAYMENT',
        amount,
        source: purposeWalletName,
        destination: merchantName,
        description: `Paid to ${merchantName}`,
        status: 'SUCCESS',
      },
    });

    return { success: true, payment };
  });
}

async function sumUserSpending(userId) {
  const result = await prisma.merchantPayment.aggregate({
    where: { userId, status: 'SUCCESS' },
    _sum: { amount: true },
  });
  return result._sum.amount;
}

async function writeAuditLog(userId, action, metadata, ipAddress) {
  await prisma.auditLog.create({ data: { userId, action, metadata, ipAddress } });
}

module.exports = { listActive, findById, executePayment, sumUserSpending, writeAuditLog };
