const prisma = require('../config/prisma');

const QR_TTL_MINUTES = 10;

async function create(merchantId) {
  const expiresAt = new Date(Date.now() + QR_TTL_MINUTES * 60 * 1000);
  return prisma.merchantQrCode.create({ data: { merchantId, expiresAt } });
}

async function findById(qrId) {
  return prisma.merchantQrCode.findUnique({ where: { id: qrId }, include: { merchant: true } });
}

async function expire(qrId) {
  await prisma.merchantQrCode.updateMany({ where: { id: qrId, status: 'ACTIVE' }, data: { status: 'EXPIRED' } });
}

// Atomic compare-and-swap: only succeeds if the QR is still ACTIVE at the
// moment of the update, so two concurrent (or replayed) payment attempts
// against the same QR can never both succeed. This single operation is what
// prevents replay attacks and duplicate payments.
async function consume(qrId) {
  const result = await prisma.merchantQrCode.updateMany({
    where: { id: qrId, status: 'ACTIVE' },
    data: { status: 'USED', usedAt: new Date() },
  });
  return result.count === 1;
}

// Releases a QR back to ACTIVE after it was consumed but the downstream
// payment failed (e.g. insufficient balance) — only a QR this exact request
// just consumed and never linked to a successful payment can be reversed.
async function release(qrId) {
  await prisma.merchantQrCode.updateMany({
    where: { id: qrId, status: 'USED', merchantPaymentId: null },
    data: { status: 'ACTIVE', usedAt: null },
  });
}

async function linkPayment(qrId, merchantPaymentId) {
  await prisma.merchantQrCode.update({ where: { id: qrId }, data: { merchantPaymentId } });
}

async function writeAuditLog(userId, action, metadata, ipAddress) {
  await prisma.auditLog.create({ data: { userId, action, metadata, ipAddress } });
}

module.exports = { create, findById, expire, consume, release, linkPayment, writeAuditLog };
