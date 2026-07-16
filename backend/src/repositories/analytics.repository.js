const prisma = require('../config/prisma');

// One query, covers every purpose wallet and every transaction type at once
// — the shared source both dashboard totals (summed across wallets) and
// Purpose Wallet Analytics (grouped by wallet) are derived from in JS,
// avoiding N separate per-wallet queries.
async function groupTransactionsByWalletAndType(userId, { start, end }) {
  return prisma.walletTransaction.groupBy({
    by: ['purposeWalletId', 'type'],
    where: { userId, createdAt: { gte: start, lt: end } },
    _sum: { amount: true },
    _count: { _all: true },
  });
}

// All-time (not window-scoped) last-activity date per wallet — dormant-wallet
// insights are about real-world recency, not whatever filter happens to be
// selected on the Dashboard.
async function lastActivityByWallet(userId) {
  return prisma.walletTransaction.groupBy({
    by: ['purposeWalletId'],
    where: { userId, purposeWalletId: { not: null } },
    _max: { createdAt: true },
  });
}

// Raw {amount, createdAt} rows for expense-type transactions in a window —
// used to bucket by calendar month/day in JS (Prisma groupBy can't bucket by
// a date-truncated key without raw SQL, which this codebase has never used).
async function findExpenseTransactions(userId, { start, end }, types) {
  return prisma.walletTransaction.findMany({
    where: { userId, type: { in: types }, createdAt: { gte: start, lt: end } },
    select: { amount: true, createdAt: true },
  });
}

async function sumScheduledExecutions(userId, { start, end }) {
  const result = await prisma.scheduledPaymentExecution.aggregate({
    where: { status: 'SUCCESS', executedAt: { gte: start, lt: end }, scheduledPayment: { userId } },
    _sum: { amount: true },
  });
  return result._sum.amount;
}

module.exports = {
  groupTransactionsByWalletAndType,
  lastActivityByWallet,
  findExpenseTransactions,
  sumScheduledExecutions,
};
