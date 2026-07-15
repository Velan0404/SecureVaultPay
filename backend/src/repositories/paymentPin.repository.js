const prisma = require('../config/prisma');

async function findByUserId(userId) {
  return prisma.paymentPin.findUnique({ where: { userId } });
}

async function create(userId, pinHash) {
  return prisma.paymentPin.create({ data: { userId, pinHash } });
}

module.exports = { findByUserId, create };
