const jwt = require('jsonwebtoken');
const prisma = require('../config/prisma');
const AppError = require('../utils/appError');
const { generateRefreshToken, hashRefreshToken } = require('../utils/token.util');

function signAccessToken(userId) {
  return jwt.sign({ sub: userId }, process.env.JWT_ACCESS_SECRET, {
    expiresIn: process.env.JWT_ACCESS_EXPIRY || '15m',
  });
}

function verifyAccessToken(token) {
  return jwt.verify(token, process.env.JWT_ACCESS_SECRET);
}

function refreshExpiryDate() {
  const days = Number(process.env.JWT_REFRESH_EXPIRY_DAYS || 30);
  return new Date(Date.now() + days * 24 * 60 * 60 * 1000);
}

async function issueTokenPair(userId, deviceId, ipAddress) {
  const accessToken = signAccessToken(userId);
  const refreshToken = generateRefreshToken();

  await prisma.refreshToken.create({
    data: {
      userId,
      deviceId,
      tokenHash: hashRefreshToken(refreshToken),
      ipAddress,
      expiresAt: refreshExpiryDate(),
    },
  });

  return { accessToken, refreshToken };
}

async function rotateRefreshToken(presentedToken, ipAddress) {
  const tokenHash = hashRefreshToken(presentedToken);
  const existing = await prisma.refreshToken.findUnique({ where: { tokenHash } });

  if (!existing) {
    throw new AppError(401, 'TOKEN_INVALID', 'Refresh token is invalid.');
  }

  if (existing.revokedAt) {
    await prisma.refreshToken.updateMany({
      where: { userId: existing.userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    throw new AppError(401, 'TOKEN_REUSE_DETECTED', 'Refresh token reuse detected. All sessions revoked.');
  }

  if (existing.expiresAt < new Date()) {
    throw new AppError(401, 'TOKEN_EXPIRED', 'Refresh token has expired.');
  }

  await prisma.refreshToken.update({
    where: { id: existing.id },
    data: { revokedAt: new Date() },
  });

  return issueTokenPair(existing.userId, existing.deviceId, ipAddress);
}

async function revokeRefreshToken(presentedToken) {
  const tokenHash = hashRefreshToken(presentedToken);
  await prisma.refreshToken.updateMany({
    where: { tokenHash, revokedAt: null },
    data: { revokedAt: new Date() },
  });
}

async function revokeAllUserTokens(userId) {
  await prisma.refreshToken.updateMany({
    where: { userId, revokedAt: null },
    data: { revokedAt: new Date() },
  });
}

module.exports = {
  signAccessToken,
  verifyAccessToken,
  issueTokenPair,
  rotateRefreshToken,
  revokeRefreshToken,
  revokeAllUserTokens,
};
