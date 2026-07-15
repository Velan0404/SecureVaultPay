const prisma = require('../config/prisma');

async function setPhoneNumber(userId, phoneNumber) {
  return prisma.user.update({ where: { id: userId }, data: { phoneNumber } });
}

async function findUserById(userId) {
  return prisma.user.findUnique({ where: { id: userId } });
}

async function createSession({ userId, deviceId, purposeWalletId, amount, expiresAt }) {
  return prisma.transactionAuthSession.create({
    data: { userId, deviceId, purposeWalletId, amount, expiresAt },
  });
}

async function findSessionForUser(userId, sessionId) {
  return prisma.transactionAuthSession.findFirst({ where: { id: sessionId, userId } });
}

// Atomic compare-and-swap: only succeeds if the session is still in
// `fromStatus` at the moment of the update, so two concurrent requests for
// the same session can never both advance it (prevents replaying a step).
async function transitionStatus(sessionId, fromStatus, toStatus, extraData = {}) {
  const result = await prisma.transactionAuthSession.updateMany({
    where: { id: sessionId, status: fromStatus },
    data: { status: toStatus, ...extraData },
  });
  return result.count === 1;
}

async function incrementOtpAttempts(sessionId) {
  return prisma.transactionAuthSession.update({
    where: { id: sessionId },
    data: { otpAttempts: { increment: 1 } },
  });
}

async function writeAuditLog(userId, action, metadata, ipAddress) {
  await prisma.auditLog.create({ data: { userId, action, metadata, ipAddress } });
}

module.exports = {
  setPhoneNumber,
  findUserById,
  createSession,
  findSessionForUser,
  transitionStatus,
  incrementOtpAttempts,
  writeAuditLog,
};
