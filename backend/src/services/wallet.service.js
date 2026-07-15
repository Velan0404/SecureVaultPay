const { Prisma } = require('../generated/prisma');
const AppError = require('../utils/appError');
const walletRepository = require('../repositories/wallet.repository');

const DEMO_MONEY_AMOUNT = new Prisma.Decimal('100000.00');

function toPublicMainWallet(wallet) {
  return {
    id: wallet.id,
    balance: wallet.balance,
    createdAt: wallet.createdAt,
    updatedAt: wallet.updatedAt,
  };
}

function toPublicPurposeWallet(wallet) {
  return {
    id: wallet.id,
    name: wallet.name,
    icon: wallet.icon,
    color: wallet.color,
    purpose: wallet.purpose,
    balance: wallet.balance,
    spendingLimit: wallet.spendingLimit,
    status: wallet.status,
    createdAt: wallet.createdAt,
    updatedAt: wallet.updatedAt,
  };
}

function toPublicTransaction(tx) {
  return {
    id: tx.id,
    type: tx.type,
    amount: tx.amount,
    source: tx.source,
    destination: tx.destination,
    description: tx.description,
    status: tx.status,
    purposeWalletId: tx.purposeWalletId,
    createdAt: tx.createdAt,
  };
}

async function getMainWallet(userId) {
  const wallet = await walletRepository.getOrCreateMainWallet(userId);
  return toPublicMainWallet(wallet);
}

// Demo money is a development-only convenience (per PROJECT_CONTEXT.md) and is
// only granted once per wallet — a zero balance is the signal it hasn't been
// loaded yet, which also naturally blocks re-farming after any real activity.
async function loadDemoMoney(userId) {
  if (process.env.NODE_ENV === 'production') {
    throw new AppError(403, 'DEMO_MONEY_DISABLED', 'Demo money is not available in production.');
  }

  const mainWallet = await walletRepository.getOrCreateMainWallet(userId);
  if (!mainWallet.balance.isZero()) {
    throw new AppError(400, 'DEMO_MONEY_ALREADY_LOADED', 'Demo money has already been loaded into this wallet.');
  }

  const updated = await walletRepository.loadDemoMoney({
    userId,
    mainWalletId: mainWallet.id,
    amount: DEMO_MONEY_AMOUNT,
  });
  return toPublicMainWallet(updated);
}

async function listPurposeWallets(userId) {
  const mainWallet = await walletRepository.getOrCreateMainWallet(userId);
  const wallets = await walletRepository.listPurposeWallets(mainWallet.id);
  return wallets.map(toPublicPurposeWallet);
}

// Ownership must be checked by walking Purpose Wallet -> Main Wallet -> User,
// since a Purpose Wallet has no direct userId column.
async function getOwnedPurposeWallet(userId, purposeWalletId) {
  const mainWallet = await walletRepository.getOrCreateMainWallet(userId);
  const wallet = await walletRepository.findPurposeWalletById(purposeWalletId);

  if (!wallet || wallet.mainWalletId !== mainWallet.id) {
    throw new AppError(404, 'PURPOSE_WALLET_NOT_FOUND', 'Purpose wallet not found.');
  }
  return { mainWallet, wallet };
}

async function getPurposeWallet(userId, purposeWalletId) {
  const { wallet } = await getOwnedPurposeWallet(userId, purposeWalletId);
  return toPublicPurposeWallet(wallet);
}

async function createPurposeWallet(userId, data) {
  const mainWallet = await walletRepository.getOrCreateMainWallet(userId);
  const wallet = await walletRepository.createPurposeWalletWithLog(userId, mainWallet.id, data);
  return toPublicPurposeWallet(wallet);
}

async function updatePurposeWallet(userId, purposeWalletId, data) {
  const { wallet } = await getOwnedPurposeWallet(userId, purposeWalletId);

  if (wallet.status !== 'ACTIVE') {
    throw new AppError(400, 'WALLET_ARCHIVED', 'Cannot edit an archived wallet.');
  }

  const updated = await walletRepository.updatePurposeWalletWithLog(userId, wallet, data);
  return toPublicPurposeWallet(updated);
}

// Archived (soft-deleted), not hard-deleted: WalletTransaction/WalletTransfer
// rows reference this wallet, and the transaction history must survive
// deletion so the audit trail stays intact.
async function deletePurposeWallet(userId, purposeWalletId) {
  const { wallet } = await getOwnedPurposeWallet(userId, purposeWalletId);

  if (wallet.status !== 'ACTIVE') {
    throw new AppError(400, 'WALLET_ARCHIVED', 'This wallet has already been deleted.');
  }
  if (!wallet.balance.isZero()) {
    throw new AppError(400, 'WALLET_NOT_EMPTY', 'Transfer out the remaining balance before deleting this wallet.');
  }

  await walletRepository.archivePurposeWalletWithLog(userId, wallet);
}

async function transfer(userId, { purposeWalletId, amount }) {
  const amountDecimal = new Prisma.Decimal(amount);
  if (amountDecimal.lessThanOrEqualTo(0)) {
    throw new AppError(400, 'INVALID_AMOUNT', 'Amount must be greater than zero.');
  }

  const { mainWallet, wallet } = await getOwnedPurposeWallet(userId, purposeWalletId);
  if (wallet.status !== 'ACTIVE') {
    throw new AppError(400, 'WALLET_ARCHIVED', 'Cannot transfer into an archived wallet.');
  }

  const result = await walletRepository.transferMainToPurpose({
    userId,
    mainWalletId: mainWallet.id,
    purposeWallet: wallet,
    amount: amountDecimal,
  });

  if (!result.success) {
    throw new AppError(400, 'INSUFFICIENT_BALANCE', 'Main wallet balance is insufficient for this transfer.');
  }

  return result.transfer;
}

async function listTransactions(userId, { purposeWalletId, cursor, limit = 20 } = {}) {
  const boundedLimit = Math.min(Math.max(Number(limit) || 20, 1), 100);
  const rows = await walletRepository.listTransactions(userId, { purposeWalletId, cursor, limit: boundedLimit });

  const hasMore = rows.length > boundedLimit;
  const page = hasMore ? rows.slice(0, boundedLimit) : rows;

  return {
    transactions: page.map(toPublicTransaction),
    nextCursor: hasMore ? page[page.length - 1].id : null,
  };
}

async function getDashboard(userId) {
  const mainWallet = await walletRepository.getOrCreateMainWallet(userId);
  const purposeWallets = await walletRepository.listPurposeWallets(mainWallet.id);
  const totalAllocated = await walletRepository.sumActivePurposeWalletBalances(mainWallet.id);
  const recent = await walletRepository.recentTransactions(userId, 10);

  return {
    mainWalletBalance: mainWallet.balance,
    remainingMainWalletBalance: mainWallet.balance,
    totalWallets: purposeWallets.length,
    totalAllocated,
    purposeWallets: purposeWallets.map(toPublicPurposeWallet),
    recentTransactions: recent.map(toPublicTransaction),
  };
}

module.exports = {
  getMainWallet,
  loadDemoMoney,
  listPurposeWallets,
  getPurposeWallet,
  createPurposeWallet,
  updatePurposeWallet,
  deletePurposeWallet,
  transfer,
  listTransactions,
  getDashboard,
};
