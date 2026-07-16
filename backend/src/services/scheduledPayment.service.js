const { Prisma } = require('../generated/prisma');
const AppError = require('../utils/appError');
const repository = require('../repositories/scheduledPayment.repository');
const walletService = require('./wallet.service');
const merchantService = require('./merchant.service');
const personalPaymentService = require('./personalPayment.service');

const MISSED_WINDOW_DAYS = 7;
const UPCOMING_WINDOW_DAYS = 7;

function toPublic(schedule) {
  return {
    id: schedule.id,
    title: schedule.title,
    paymentType: schedule.paymentType,
    amount: schedule.amount,
    frequency: schedule.frequency,
    customIntervalDays: schedule.customIntervalDays,
    purposeWalletId: schedule.purposeWalletId,
    merchantId: schedule.merchantId,
    merchantName: schedule.merchant?.merchantName ?? null,
    merchantLogo: schedule.merchant?.merchantLogo ?? null,
    receiverUserId: schedule.receiverUserId,
    receiverName: schedule.receiverUser?.fullName ?? null,
    note: schedule.note,
    startDate: schedule.startDate,
    nextExecution: schedule.nextExecution,
    lastExecution: schedule.lastExecution,
    endDate: schedule.endDate,
    status: schedule.status,
    createdAt: schedule.createdAt,
    updatedAt: schedule.updatedAt,
  };
}

function toPublicExecution(execution) {
  return {
    id: execution.id,
    scheduledFor: execution.scheduledFor,
    executedAt: execution.executedAt,
    status: execution.status,
    amount: execution.amount,
    failureReason: execution.failureReason,
    paymentId: execution.paymentId,
  };
}

// Called only after requirePaymentPin has verified the caller's Payment PIN
// — never directly reachable without it (same discipline as every other
// money-committing action in this app).
async function create(userId, data) {
  const amountDecimal = new Prisma.Decimal(data.amount);
  if (amountDecimal.lessThanOrEqualTo(0)) {
    throw new AppError(400, 'INVALID_AMOUNT', 'Amount must be greater than zero.');
  }

  if (Boolean(data.merchantId) === Boolean(data.receiverUserId)) {
    throw new AppError(400, 'INVALID_DESTINATION', 'Provide exactly one of merchantId or receiverUserId.');
  }
  if (data.frequency === 'CUSTOM' && !data.customIntervalDays) {
    throw new AppError(400, 'CUSTOM_INTERVAL_REQUIRED', 'customIntervalDays is required when frequency is CUSTOM.');
  }

  // Reuses the Wallet module's own ownership + active-status check — same
  // call every other payment module makes, wallet.service.js untouched.
  const wallet = await walletService.getPurposeWallet(userId, data.purposeWalletId);
  if (wallet.status !== 'ACTIVE') {
    throw new AppError(400, 'WALLET_ARCHIVED', 'Cannot schedule a payment from an archived wallet.');
  }

  if (data.merchantId) {
    const merchant = await merchantService.getMerchant(data.merchantId);
    if (merchant.status !== 'ACTIVE') {
      throw new AppError(400, 'MERCHANT_INACTIVE', 'This merchant is not available for payment.');
    }
  } else {
    if (data.receiverUserId === userId) {
      throw new AppError(400, 'SELF_PAYMENT_NOT_ALLOWED', 'You cannot schedule a payment to yourself.');
    }
    // Reuses Personal Payment's own existence + active check — no duplicate
    // lookup logic here.
    await personalPaymentService.lookupReceiver({ userId: data.receiverUserId });
  }

  const startDate = new Date(data.startDate);
  const endDate = data.endDate ? new Date(data.endDate) : null;

  const schedule = await repository.create({
    userId,
    title: data.title,
    paymentType: data.paymentType,
    amount: amountDecimal,
    frequency: data.frequency,
    customIntervalDays: data.frequency === 'CUSTOM' ? data.customIntervalDays : null,
    purposeWalletId: data.purposeWalletId,
    merchantId: data.merchantId ?? null,
    receiverUserId: data.receiverUserId ?? null,
    note: data.note ?? null,
    startDate,
    nextExecution: startDate,
    endDate,
  });

  await repository.writeAuditLog(userId, 'SCHEDULED_PAYMENT_CREATED', { scheduleId: schedule.id }, null);

  return toPublic(schedule);
}

async function getOwned(userId, id) {
  const schedule = await repository.findOwnedById(userId, id);
  if (!schedule) {
    throw new AppError(404, 'SCHEDULE_NOT_FOUND', 'Scheduled payment not found.');
  }
  return schedule;
}

async function getOne(userId, id) {
  return toPublic(await getOwned(userId, id));
}

async function list(userId, { status } = {}) {
  const schedules = await repository.list(userId, { status });
  return schedules.map(toPublic);
}

// Only amount/frequency/customIntervalDays/endDate/title/note/purposeWalletId
// are editable — the destination (merchantId/receiverUserId) and paymentType
// can never change after creation (cancel + recreate instead), so an edit
// never needs to re-validate a merchant/receiver.
async function update(userId, id, data) {
  const schedule = await getOwned(userId, id);
  if (schedule.status === 'CANCELLED' || schedule.status === 'COMPLETED') {
    throw new AppError(400, 'SCHEDULE_NOT_EDITABLE', 'This schedule can no longer be edited.');
  }

  const updateData = {};
  if (data.title !== undefined) updateData.title = data.title;
  if (data.note !== undefined) updateData.note = data.note;
  if (data.endDate !== undefined) updateData.endDate = data.endDate ? new Date(data.endDate) : null;

  if (data.purposeWalletId !== undefined) {
    const wallet = await walletService.getPurposeWallet(userId, data.purposeWalletId);
    if (wallet.status !== 'ACTIVE') {
      throw new AppError(400, 'WALLET_ARCHIVED', 'Cannot schedule a payment from an archived wallet.');
    }
    updateData.purposeWalletId = data.purposeWalletId;
  }

  if (data.amount !== undefined) {
    const amountDecimal = new Prisma.Decimal(data.amount);
    if (amountDecimal.lessThanOrEqualTo(0)) {
      throw new AppError(400, 'INVALID_AMOUNT', 'Amount must be greater than zero.');
    }
    updateData.amount = amountDecimal;
  }

  if (data.frequency !== undefined) {
    const customIntervalDays = data.frequency === 'CUSTOM' ? data.customIntervalDays : null;
    if (data.frequency === 'CUSTOM' && !customIntervalDays) {
      throw new AppError(400, 'CUSTOM_INTERVAL_REQUIRED', 'customIntervalDays is required when frequency is CUSTOM.');
    }
    updateData.frequency = data.frequency;
    updateData.customIntervalDays = customIntervalDays;
  }

  const updated = await repository.update(id, updateData);
  await repository.writeAuditLog(userId, 'SCHEDULED_PAYMENT_UPDATED', { scheduleId: id, fields: Object.keys(updateData) }, null);
  return toPublic(updated);
}

async function setStatus(userId, id, { from, to, action }) {
  const schedule = await getOwned(userId, id);
  if (schedule.status !== from) {
    throw new AppError(400, 'INVALID_STATUS_TRANSITION', `Only a ${from.toLowerCase()} schedule can be ${action}.`);
  }

  const updateData = { status: to };
  // Resuming a schedule that was paused past its due date shouldn't be
  // silently "overdue forever" — bump it to run on the very next tick.
  if (to === 'ACTIVE' && schedule.nextExecution < new Date()) {
    updateData.nextExecution = new Date();
  }

  const updated = await repository.update(id, updateData);
  await repository.writeAuditLog(userId, `SCHEDULED_PAYMENT_${action.toUpperCase()}`, { scheduleId: id }, null);
  return toPublic(updated);
}

async function pause(userId, id) {
  return setStatus(userId, id, { from: 'ACTIVE', to: 'PAUSED', action: 'paused' });
}

async function resume(userId, id) {
  return setStatus(userId, id, { from: 'PAUSED', to: 'ACTIVE', action: 'resumed' });
}

async function cancel(userId, id) {
  const schedule = await getOwned(userId, id);
  if (schedule.status === 'CANCELLED') {
    throw new AppError(400, 'INVALID_STATUS_TRANSITION', 'This schedule is already cancelled.');
  }
  const updated = await repository.update(id, { status: 'CANCELLED' });
  await repository.writeAuditLog(userId, 'SCHEDULED_PAYMENT_CANCELLED', { scheduleId: id }, null);
  return toPublic(updated);
}

async function listExecutions(userId, id, { cursor, limit = 20 } = {}) {
  await getOwned(userId, id); // ownership check
  const boundedLimit = Math.min(Math.max(Number(limit) || 20, 1), 100);
  const rows = await repository.listExecutions(id, { cursor, limit: boundedLimit });

  const hasMore = rows.length > boundedLimit;
  const page = hasMore ? rows.slice(0, boundedLimit) : rows;

  return {
    executions: page.map(toPublicExecution),
    nextCursor: hasMore ? page[page.length - 1].id : null,
  };
}

async function getDashboardSummary(userId) {
  const now = new Date();
  const startOfToday = new Date(now);
  startOfToday.setHours(0, 0, 0, 0);
  const startOfTomorrow = new Date(startOfToday);
  startOfTomorrow.setDate(startOfTomorrow.getDate() + 1);
  const in7Days = new Date(now);
  in7Days.setDate(in7Days.getDate() + UPCOMING_WINDOW_DAYS);
  const sevenDaysAgo = new Date(now);
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - MISSED_WINDOW_DAYS);

  const [today, upcoming, missed, activeCount, pausedCount] = await Promise.all([
    repository.findByStatusAndWindow(userId, { gte: startOfToday, lt: startOfTomorrow }),
    repository.findByStatusAndWindow(userId, { gte: startOfTomorrow, lt: in7Days }),
    repository.findRecentlyFailed(userId, sevenDaysAgo),
    repository.countByStatus(userId, 'ACTIVE'),
    repository.countByStatus(userId, 'PAUSED'),
  ]);

  const upcoming7DayTotal = [...today, ...upcoming].reduce(
    (sum, s) => sum.plus(s.amount),
    new Prisma.Decimal(0),
  );

  return {
    today: today.map(toPublic),
    upcoming: upcoming.map(toPublic),
    missed: missed.map(toPublic),
    stats: {
      activeCount,
      pausedCount,
      missedCount: missed.length,
      upcoming7DayTotal,
    },
  };
}

module.exports = {
  toPublic,
  create,
  getOne,
  list,
  update,
  pause,
  resume,
  cancel,
  listExecutions,
  getDashboardSummary,
};
