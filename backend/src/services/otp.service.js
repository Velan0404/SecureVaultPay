const prisma = require('../config/prisma');
const AppError = require('../utils/appError');
const { generateOtp, hashOtp, verifyOtpHash } = require('../utils/otp.util');

function otpExpiryDate() {
  const minutes = Number(process.env.OTP_EXPIRY_MINUTES || 10);
  return new Date(Date.now() + minutes * 60 * 1000);
}

function maxAttempts() {
  return Number(process.env.OTP_MAX_ATTEMPTS || 5);
}

async function issueOtp(userId) {
  // Generating a new OTP invalidates every previous OTP for this user.
  await prisma.passwordResetOtp.updateMany({
    where: { userId, consumedAt: null },
    data: { consumedAt: new Date() },
  });

  const otp = generateOtp();

  await prisma.passwordResetOtp.create({
    data: {
      userId,
      otpHash: hashOtp(otp),
      expiresAt: otpExpiryDate(),
    },
  });

  return otp;
}

async function verifyOtp(userId, otp) {
  const record = await prisma.passwordResetOtp.findFirst({
    where: { userId, consumedAt: null },
    orderBy: { createdAt: 'desc' },
  });

  if (!record || record.expiresAt < new Date() || record.attempts >= maxAttempts()) {
    throw new AppError(400, 'OTP_INVALID_OR_EXPIRED', 'Invalid or expired OTP.');
  }

  if (!verifyOtpHash(otp, record.otpHash)) {
    await prisma.passwordResetOtp.update({
      where: { id: record.id },
      data: { attempts: { increment: 1 } },
    });
    throw new AppError(400, 'OTP_INVALID_OR_EXPIRED', 'Invalid or expired OTP.');
  }

  await prisma.passwordResetOtp.update({
    where: { id: record.id },
    data: { consumedAt: new Date() },
  });
}

module.exports = { issueOtp, verifyOtp };
