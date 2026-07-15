const prisma = require('../config/prisma');
const { Prisma } = require('../generated/prisma');

async function findMainWalletByUserId(userId) {
  return prisma.mainWallet.findUnique({ where: { userId } });
}

// Ensures every user has exactly one Main Wallet without requiring a hook in
// the Authentication module — created lazily on first access instead of at
// registration time, so pre-existing users are covered too.
async function getOrCreateMainWallet(userId) {
  const existing = await findMainWalletByUserId(userId);
  if (existing) return existing;

  try {
    return await prisma.mainWallet.create({ data: { userId } });
  } catch (err) {
    if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002') {
      // Lost a create race to a concurrent request — read back what it wrote.
      return findMainWalletByUserId(userId);
    }
    throw err;
  }
}

async function findPurposeWalletById(id) {
  return prisma.purposeWallet.findUnique({ where: { id } });
}

async function listPurposeWallets(mainWalletId, { includeArchived = false } = {}) {
  return prisma.purposeWallet.findMany({
    where: { mainWalletId, ...(includeArchived ? {} : { status: 'ACTIVE' }) },
    orderBy: { createdAt: 'asc' },
  });
}

async function sumActivePurposeWalletBalances(mainWalletId) {
  const result = await prisma.purposeWallet.aggregate({
    where: { mainWalletId, status: 'ACTIVE' },
    _sum: { balance: true },
  });
  return result._sum.balance ?? new Prisma.Decimal(0);
}

async function createPurposeWalletWithLog(userId, mainWalletId, data) {
  return prisma.$transaction(async (tx) => {
    const wallet = await tx.purposeWallet.create({
      data: {
        mainWalletId,
        name: data.name,
        icon: data.icon,
        color: data.color,
        purpose: data.purpose,
        spendingLimit: data.spendingLimit,
      },
    });
    await tx.walletTransaction.create({
      data: {
        userId,
        mainWalletId,
        purposeWalletId: wallet.id,
        type: 'WALLET_CREATED',
        amount: new Prisma.Decimal(0),
        destination: wallet.name,
        description: `Purpose wallet "${wallet.name}" created`,
        status: 'SUCCESS',
      },
    });
    return wallet;
  });
}

async function updatePurposeWalletWithLog(userId, wallet, data) {
  return prisma.$transaction(async (tx) => {
    const updated = await tx.purposeWallet.update({
      where: { id: wallet.id },
      data: {
        name: data.name,
        icon: data.icon,
        color: data.color,
        purpose: data.purpose,
        spendingLimit: data.spendingLimit,
      },
    });
    await tx.walletTransaction.create({
      data: {
        userId,
        mainWalletId: wallet.mainWalletId,
        purposeWalletId: wallet.id,
        type: 'WALLET_UPDATED',
        amount: new Prisma.Decimal(0),
        destination: updated.name,
        description: `Purpose wallet "${updated.name}" updated`,
        status: 'SUCCESS',
      },
    });
    return updated;
  });
}

async function archivePurposeWalletWithLog(userId, wallet) {
  return prisma.$transaction(async (tx) => {
    const archived = await tx.purposeWallet.update({
      where: { id: wallet.id },
      data: { status: 'ARCHIVED' },
    });
    await tx.walletTransaction.create({
      data: {
        userId,
        mainWalletId: wallet.mainWalletId,
        purposeWalletId: wallet.id,
        type: 'WALLET_DELETED',
        amount: new Prisma.Decimal(0),
        source: archived.name,
        description: `Purpose wallet "${archived.name}" deleted`,
        status: 'SUCCESS',
      },
    });
    return archived;
  });
}

// Atomically moves money Main -> Purpose. The conditional `updateMany` only
// affects a row if the balance is still sufficient at the moment Postgres
// takes the row lock, so two concurrent transfers can never both succeed
// against the same insufficient balance (classic compare-and-swap guard —
// no explicit `SELECT ... FOR UPDATE` needed).
async function transferMainToPurpose({ userId, mainWalletId, purposeWallet, amount }) {
  return prisma.$transaction(async (tx) => {
    const debited = await tx.mainWallet.updateMany({
      where: { id: mainWalletId, balance: { gte: amount } },
      data: { balance: { decrement: amount } },
    });

    if (debited.count === 0) {
      return { success: false };
    }

    await tx.purposeWallet.update({
      where: { id: purposeWallet.id },
      data: { balance: { increment: amount } },
    });

    const transfer = await tx.walletTransfer.create({
      data: { mainWalletId, purposeWalletId: purposeWallet.id, amount },
    });

    await tx.walletTransaction.create({
      data: {
        userId,
        mainWalletId,
        purposeWalletId: purposeWallet.id,
        type: 'MAIN_TO_PURPOSE',
        amount,
        source: 'Main Wallet',
        destination: purposeWallet.name,
        description: `Transferred to ${purposeWallet.name}`,
        status: 'SUCCESS',
      },
    });

    return { success: true, transfer };
  });
}

async function loadDemoMoney({ userId, mainWalletId, amount }) {
  return prisma.$transaction(async (tx) => {
    const wallet = await tx.mainWallet.update({
      where: { id: mainWalletId },
      data: { balance: { increment: amount } },
    });

    await tx.walletTransaction.create({
      data: {
        userId,
        mainWalletId,
        type: 'DEMO_LOAD',
        amount,
        destination: 'Main Wallet',
        description: 'Demo wallet money loaded',
        status: 'SUCCESS',
      },
    });

    return wallet;
  });
}

async function listTransactions(userId, { purposeWalletId, cursor, limit = 20 } = {}) {
  return prisma.walletTransaction.findMany({
    where: { userId, ...(purposeWalletId ? { purposeWalletId } : {}) },
    orderBy: { createdAt: 'desc' },
    take: limit + 1,
    ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
  });
}

async function recentTransactions(userId, limit = 10) {
  return prisma.walletTransaction.findMany({
    where: { userId },
    orderBy: { createdAt: 'desc' },
    take: limit,
  });
}

module.exports = {
  findMainWalletByUserId,
  getOrCreateMainWallet,
  findPurposeWalletById,
  listPurposeWallets,
  sumActivePurposeWalletBalances,
  createPurposeWalletWithLog,
  updatePurposeWalletWithLog,
  archivePurposeWalletWithLog,
  transferMainToPurpose,
  loadDemoMoney,
  listTransactions,
  recentTransactions,
};
