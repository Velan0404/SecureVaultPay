const prisma = require('../config/prisma');

const DESTINATION_INCLUDE = {
  merchant: { select: { id: true, merchantName: true, merchantLogo: true } },
  receiverUser: { select: { id: true, fullName: true } },
};

async function create(data) {
  return prisma.scheduledPayment.create({ data, include: DESTINATION_INCLUDE });
}

async function findOwnedById(userId, id) {
  return prisma.scheduledPayment.findFirst({ where: { id, userId }, include: DESTINATION_INCLUDE });
}

async function list(userId, { status } = {}) {
  return prisma.scheduledPayment.findMany({
    where: { userId, ...(status ? { status } : {}) },
    include: DESTINATION_INCLUDE,
    orderBy: { nextExecution: 'asc' },
  });
}

async function update(id, data) {
  return prisma.scheduledPayment.update({ where: { id }, data, include: DESTINATION_INCLUDE });
}

async function listExecutions(scheduledPaymentId, { cursor, limit = 20 } = {}) {
  return prisma.scheduledPaymentExecution.findMany({
    where: { scheduledPaymentId },
    orderBy: { executedAt: 'desc' },
    take: limit + 1,
    ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
  });
}

// Dashboard summary — see scheduledPayment.service.js for the "missed"
// definition (an ACTIVE schedule with a FAILED execution in the last 7 days;
// deliberately simple for this MVP rather than tracking "most recent
// execution per schedule" precisely).
async function findByStatusAndWindow(userId, { statusFilter = 'ACTIVE', gte, lt } = {}) {
  return prisma.scheduledPayment.findMany({
    where: {
      userId,
      status: statusFilter,
      ...(gte || lt ? { nextExecution: { ...(gte ? { gte } : {}), ...(lt ? { lt } : {}) } } : {}),
    },
    include: DESTINATION_INCLUDE,
    orderBy: { nextExecution: 'asc' },
  });
}

async function countByStatus(userId, status) {
  return prisma.scheduledPayment.count({ where: { userId, status } });
}

async function findRecentlyFailed(userId, since) {
  const failedExecutions = await prisma.scheduledPaymentExecution.findMany({
    where: { status: 'FAILED', executedAt: { gte: since }, scheduledPayment: { userId, status: 'ACTIVE' } },
    distinct: ['scheduledPaymentId'],
    orderBy: { executedAt: 'desc' },
    select: { scheduledPaymentId: true },
  });
  const ids = failedExecutions.map((e) => e.scheduledPaymentId);
  if (ids.length === 0) return [];
  return prisma.scheduledPayment.findMany({ where: { id: { in: ids } }, include: DESTINATION_INCLUDE });
}

// --- Scheduler-only queries (cross-user, background job) ---

// Prisma has no column-to-column comparison in its query API, so the
// "lastReminderFor != nextExecution" dedup check is done in JS after
// fetching the (small, bounded) candidate window — simplest correct option
// short of a raw SQL query.
async function findDueForReminder(now, in24h) {
  const candidates = await prisma.scheduledPayment.findMany({
    where: { status: 'ACTIVE', nextExecution: { gte: now, lte: in24h } },
    take: 200,
  });
  return candidates.filter((s) => s.lastReminderFor?.getTime() !== s.nextExecution.getTime());
}

async function findDueForExecution(now) {
  return prisma.scheduledPayment.findMany({
    where: { status: 'ACTIVE', nextExecution: { lte: now } },
    take: 100,
  });
}

async function markReminderSent(id, nextExecution) {
  await prisma.scheduledPayment.updateMany({
    where: { id, nextExecution },
    data: { lastReminderFor: nextExecution },
  });
}

// Atomic claim: only succeeds if nobody else already advanced this exact
// due cycle. See scheduler.service.js for why this runs BEFORE the payment
// call (claim-then-pay, never pay-then-claim).
async function claimDueCycle(id, dueAt, { nextExecution, status } = {}) {
  return prisma.scheduledPayment.updateMany({
    where: { id, nextExecution: dueAt, status: 'ACTIVE' },
    data: { nextExecution, lastExecution: new Date(), status },
  });
}

async function createExecution(data) {
  return prisma.scheduledPaymentExecution.create({ data });
}

async function writeAuditLog(userId, action, metadata, ipAddress) {
  await prisma.auditLog.create({ data: { userId, action, metadata, ipAddress } });
}

module.exports = {
  create,
  findOwnedById,
  list,
  update,
  listExecutions,
  findByStatusAndWindow,
  countByStatus,
  findRecentlyFailed,
  findDueForReminder,
  findDueForExecution,
  markReminderSent,
  claimDueCycle,
  createExecution,
  writeAuditLog,
};
