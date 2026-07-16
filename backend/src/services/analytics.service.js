const { Prisma } = require('../generated/prisma');
const AppError = require('../utils/appError');
const repository = require('../repositories/analytics.repository');
const walletService = require('./wallet.service');
const scheduledPaymentService = require('./scheduledPayment.service');
const { resolveRange } = require('../utils/dateRange');

// Money entering the system (credited into a wallet from outside the user's
// own control) vs money leaving it (paid to a Merchant or another user).
// MAIN_TO_PURPOSE/PURPOSE_TO_MAIN are internal transfers between the user's
// own wallets — never counted as income or expense.
const INCOME_TYPES = ['DEMO_LOAD', 'PERSONAL_PAYMENT_RECEIVED'];
const EXPENSE_TYPES = ['PURPOSE_PAYMENT', 'PERSONAL_PAYMENT_SENT'];
const TRANSFER_TYPES = ['MAIN_TO_PURPOSE', 'PURPOSE_TO_MAIN'];
const DEPOSIT_TYPES = ['MAIN_TO_PURPOSE'];
const SPEND_TYPES = EXPENSE_TYPES; // "money that left this Purpose Wallet"

const ZERO = new Prisma.Decimal(0);
const DORMANT_DAYS = 30;
const BUDGET_WARNING_PCT = 90;
const BUDGET_INFO_PCT = 50;
const TREND_THRESHOLD_PCT = 15;
const MONTHLY_CHART_MONTHS = 6;

function sumByTypes(rows, types, { purposeWalletId } = {}) {
  return rows
    .filter((r) => types.includes(r.type) && (purposeWalletId === undefined || r.purposeWalletId === purposeWalletId))
    .reduce((sum, r) => sum.plus(r._sum.amount ?? ZERO), ZERO);
}

function countByWallet(rows, purposeWalletId) {
  return rows
    .filter((r) => r.purposeWalletId === purposeWalletId && [...DEPOSIT_TYPES, ...SPEND_TYPES].includes(r.type))
    .reduce((sum, r) => sum + r._count._all, 0);
}

function dateKey(d) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

function monthKey(d) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
}

// Shared by both the Dashboard totals endpoint and the Reports endpoint —
// one aggregation function, two callers, so "do not duplicate calculations"
// holds at the code level too.
async function computeTotals(userId, { start, end }) {
  const [rows, scheduledTotal] = await Promise.all([
    repository.groupTransactionsByWalletAndType(userId, { start, end }),
    repository.sumScheduledExecutions(userId, { start, end }),
  ]);

  return {
    totalIncome: sumByTypes(rows, INCOME_TYPES),
    totalExpenses: sumByTypes(rows, EXPENSE_TYPES),
    totalTransfers: sumByTypes(rows, TRANSFER_TYPES),
    totalMerchantPayments: sumByTypes(rows, ['PURPOSE_PAYMENT']),
    totalUserPayments: sumByTypes(rows, ['PERSONAL_PAYMENT_SENT']),
    totalScheduledPayments: scheduledTotal ?? ZERO,
  };
}

async function computeCurrentMonthSpending(userId) {
  const now = new Date();
  const start = new Date(now.getFullYear(), now.getMonth(), 1);
  const end = new Date(now.getFullYear(), now.getMonth() + 1, 1);
  const rows = await repository.groupTransactionsByWalletAndType(userId, { start, end });
  return sumByTypes(rows, EXPENSE_TYPES);
}

async function getDashboardAnalytics(userId, query) {
  const { start, end, preset } = resolveRange(query);
  const [totals, walletDashboard, monthlySpending] = await Promise.all([
    computeTotals(userId, { start, end }),
    walletService.getDashboard(userId),
    computeCurrentMonthSpending(userId),
  ]);

  const totalBalance = new Prisma.Decimal(walletDashboard.mainWalletBalance).plus(walletDashboard.totalAllocated);

  return {
    totalBalance,
    ...totals,
    monthlySpending,
    range: { preset, startDate: start, endDate: end },
  };
}

// Reused by both the Purpose Wallet Analytics endpoint and the Insights
// engine (which needs each wallet's spendingPercentage/totalSpent) — never
// recomputed twice in the same request.
async function computeWalletAnalytics(userId, { start, end }) {
  const [rows, walletDashboard] = await Promise.all([
    repository.groupTransactionsByWalletAndType(userId, { start, end }),
    walletService.getDashboard(userId),
  ]);

  return walletDashboard.purposeWallets.map((wallet) => {
    const totalDeposited = sumByTypes(rows, DEPOSIT_TYPES, { purposeWalletId: wallet.id });
    const totalSpent = sumByTypes(rows, SPEND_TYPES, { purposeWalletId: wallet.id });
    const transactionCount = countByWallet(rows, wallet.id);
    const spendingLimit = wallet.spendingLimit ? new Prisma.Decimal(wallet.spendingLimit) : null;
    const remainingBudget = spendingLimit ? spendingLimit.minus(totalSpent) : null;
    const spendingPercentage =
      spendingLimit && !spendingLimit.isZero() ? totalSpent.dividedBy(spendingLimit).times(100) : null;

    return {
      walletId: wallet.id,
      name: wallet.name,
      icon: wallet.icon,
      color: wallet.color,
      currentBalance: new Prisma.Decimal(wallet.balance),
      totalDeposited,
      totalSpent,
      remainingBudget,
      spendingPercentage,
      transactionCount,
    };
  });
}

async function getWalletAnalytics(userId, query) {
  const { start, end, preset } = resolveRange(query);
  const wallets = await computeWalletAnalytics(userId, { start, end });
  return { wallets, range: { preset, startDate: start, endDate: end } };
}

async function computeMonthlySpendingSeries(userId) {
  const now = new Date();
  const start = new Date(now.getFullYear(), now.getMonth() - (MONTHLY_CHART_MONTHS - 1), 1);
  const end = new Date(now.getFullYear(), now.getMonth() + 1, 1);
  const rows = await repository.findExpenseTransactions(userId, { start, end }, EXPENSE_TYPES);

  const buckets = new Map();
  for (let i = 0; i < MONTHLY_CHART_MONTHS; i += 1) {
    const d = new Date(now.getFullYear(), now.getMonth() - (MONTHLY_CHART_MONTHS - 1) + i, 1);
    buckets.set(monthKey(d), ZERO);
  }
  for (const row of rows) {
    const key = monthKey(row.createdAt);
    if (buckets.has(key)) buckets.set(key, buckets.get(key).plus(row.amount));
  }
  return Array.from(buckets.entries()).map(([month, total]) => ({ month, total }));
}

async function computeWeeklyExpenseSeries(userId) {
  const now = new Date();
  const startOfToday = new Date(now);
  startOfToday.setHours(0, 0, 0, 0);
  const start = new Date(startOfToday);
  start.setDate(start.getDate() - 6); // 7 days inclusive of today
  const end = new Date(startOfToday);
  end.setDate(end.getDate() + 1);

  const rows = await repository.findExpenseTransactions(userId, { start, end }, EXPENSE_TYPES);

  const buckets = new Map();
  for (let i = 0; i < 7; i += 1) {
    const d = new Date(start);
    d.setDate(d.getDate() + i);
    buckets.set(dateKey(d), ZERO);
  }
  for (const row of rows) {
    const key = dateKey(row.createdAt);
    if (buckets.has(key)) buckets.set(key, buckets.get(key).plus(row.amount));
  }
  return Array.from(buckets.entries()).map(([date, total]) => ({ date, total }));
}

async function getCharts(userId, query) {
  const { start, end, preset } = resolveRange(query);

  const [totals, monthlySpending, weeklyExpense, walletRows, walletDashboard] = await Promise.all([
    computeTotals(userId, { start, end }),
    computeMonthlySpendingSeries(userId),
    computeWeeklyExpenseSeries(userId),
    repository.groupTransactionsByWalletAndType(userId, { start, end }),
    walletService.getDashboard(userId),
  ]);

  const purposeWalletBreakdown = walletDashboard.purposeWallets
    .map((wallet) => ({
      walletId: wallet.id,
      name: wallet.name,
      color: wallet.color,
      value: sumByTypes(walletRows, SPEND_TYPES, { purposeWalletId: wallet.id }),
    }))
    .filter((entry) => !entry.value.isZero());

  return {
    monthlySpending,
    purposeWalletBreakdown,
    weeklyExpense,
    incomeVsExpense: { income: totals.totalIncome, expenses: totals.totalExpenses },
    range: { preset, startDate: start, endDate: end },
  };
}

// A small rules engine over data the endpoints above already compute —
// never re-queries what's already been fetched, only the two additional
// small lookups (prior-period comparison, all-time last-activity) that
// genuinely need fresh data.
async function getInsights(userId, query) {
  const { start, end, preset } = resolveRange(query);
  const periodLengthMs = end.getTime() - start.getTime();
  const priorStart = new Date(start.getTime() - periodLengthMs);

  const [wallets, priorRows, lastActivityRows, scheduleDashboard] = await Promise.all([
    computeWalletAnalytics(userId, { start, end }),
    repository.groupTransactionsByWalletAndType(userId, { start: priorStart, end: start }),
    repository.lastActivityByWallet(userId),
    scheduledPaymentService.getDashboardSummary(userId),
  ]);

  const lastActivityByWalletId = new Map(lastActivityRows.map((r) => [r.purposeWalletId, r._max.createdAt]));
  const now = new Date();
  const insights = [];

  for (const wallet of wallets) {
    if (wallet.spendingPercentage !== null) {
      const pct = wallet.spendingPercentage;
      if (pct.greaterThanOrEqualTo(BUDGET_WARNING_PCT)) {
        insights.push({
          id: `budget-${wallet.walletId}`,
          type: 'BUDGET_WARNING',
          severity: 'WARNING',
          message: `${wallet.name} Wallet reached ${pct.toFixed(0)}% of its budget.`,
        });
      } else if (pct.greaterThanOrEqualTo(BUDGET_INFO_PCT)) {
        insights.push({
          id: `budget-${wallet.walletId}`,
          type: 'BUDGET_INFO',
          severity: 'INFO',
          message: `You spent ${pct.toFixed(0)}% of your ${wallet.name} budget.`,
        });
      }
    }

    const priorSpent = sumByTypes(priorRows, SPEND_TYPES, { purposeWalletId: wallet.walletId });
    if (!priorSpent.isZero()) {
      const change = wallet.totalSpent.minus(priorSpent).dividedBy(priorSpent).times(100);
      if (change.abs().greaterThanOrEqualTo(TREND_THRESHOLD_PCT)) {
        const direction = change.greaterThan(0) ? 'increased' : 'decreased';
        insights.push({
          id: `trend-${wallet.walletId}`,
          type: 'TREND',
          severity: change.greaterThan(0) ? 'WARNING' : 'INFO',
          message: `${wallet.name} spending ${direction} by ${change.abs().toFixed(0)}%.`,
        });
      }
    }

    // "Last activity" is the true max(createdAt) across every WalletTransaction
    // type for this wallet (including administrative rows like WALLET_CREATED)
    // — a simplification, but one that still correctly reflects "nothing has
    // happened here in a while" for a wallet that's genuinely gone quiet.
    const lastActivity = lastActivityByWalletId.get(wallet.walletId);
    const daysSince = lastActivity ? (now - lastActivity) / (1000 * 60 * 60 * 24) : null;
    if (daysSince !== null && daysSince >= DORMANT_DAYS) {
      insights.push({
        id: `dormant-${wallet.walletId}`,
        type: 'DORMANT',
        severity: 'INFO',
        message: `${wallet.name} Wallet has not been used for ${Math.floor(daysSince)} days.`,
      });
    }
  }

  for (const schedule of scheduleDashboard.today) {
    insights.push({
      id: `upcoming-${schedule.id}`,
      type: 'UPCOMING_PAYMENT',
      severity: 'INFO',
      message: `${schedule.title} payment is due today.`,
    });
  }

  return { insights, range: { preset, startDate: start, endDate: end } };
}

const REPORT_PERIODS = ['DAILY', 'WEEKLY', 'MONTHLY'];

function resolvePeriod(period, dateStr) {
  if (!period || !REPORT_PERIODS.includes(period)) {
    throw new AppError(400, 'INVALID_PERIOD', `period must be one of: ${REPORT_PERIODS.join(', ')}.`);
  }
  const base = dateStr ? new Date(dateStr) : new Date();
  if (Number.isNaN(base.getTime())) {
    throw new AppError(400, 'INVALID_PERIOD', 'date must be a valid ISO date.');
  }

  if (period === 'DAILY') {
    const start = new Date(base);
    start.setHours(0, 0, 0, 0);
    const end = new Date(start);
    end.setDate(end.getDate() + 1);
    return { start, end };
  }
  if (period === 'WEEKLY') {
    const start = new Date(base);
    start.setHours(0, 0, 0, 0);
    const day = start.getDay(); // 0 = Sunday
    const diffToMonday = day === 0 ? 6 : day - 1;
    start.setDate(start.getDate() - diffToMonday);
    const end = new Date(start);
    end.setDate(end.getDate() + 7);
    return { start, end };
  }
  const start = new Date(base.getFullYear(), base.getMonth(), 1);
  const end = new Date(base.getFullYear(), base.getMonth() + 1, 1);
  return { start, end };
}

async function getReport(userId, { period, date }) {
  const { start, end } = resolvePeriod(period, date);
  const totals = await computeTotals(userId, { start, end });
  return { period, startDate: start, endDate: end, ...totals };
}

module.exports = {
  getDashboardAnalytics,
  getWalletAnalytics,
  getCharts,
  getInsights,
  getReport,
};
