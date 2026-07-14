const prisma = require('../config/prisma');
const AppError = require('../utils/appError');
const { hashPassword, comparePassword } = require('../utils/password.util');
const tokenService = require('./token.service');
const deviceService = require('./device.service');
const otpService = require('./otp.service');
const emailService = require('./email.service');
const notificationService = require('./notification.service');

const PIN_REGEX = /^\d{6}$/;

async function writeAuditLog(userId, action, metadata, ipAddress) {
  await prisma.auditLog.create({
    data: { userId, action, metadata, ipAddress },
  });
}

function toPublicUser(user) {
  return {
    id: user.id,
    fullName: user.fullName,
    email: user.email,
    biometricEnabled: user.biometricEnabled,
    createdAt: user.createdAt,
  };
}

async function register({ fullName, email, password, device }, ipAddress) {
  const normalizedEmail = email.trim().toLowerCase();

  const existing = await prisma.user.findUnique({ where: { email: normalizedEmail } });
  if (existing) {
    throw new AppError(409, 'EMAIL_ALREADY_EXISTS', 'An account with this email already exists.');
  }

  const passwordHash = await hashPassword(password);
  const user = await prisma.user.create({
    data: { fullName, email: normalizedEmail, passwordHash },
  });

  const { device: deviceRecord } = await deviceService.upsertDevice(user.id, device);
  const tokens = await tokenService.issueTokenPair(user.id, deviceRecord.id, ipAddress);

  await writeAuditLog(user.id, 'REGISTER', null, ipAddress);

  return { user: toPublicUser(user), ...tokens };
}

async function login({ email, password, device }, ipAddress) {
  const normalizedEmail = email.trim().toLowerCase();
  const user = await prisma.user.findUnique({ where: { email: normalizedEmail } });

  if (!user || !(await comparePassword(password, user.passwordHash))) {
    if (user) await writeAuditLog(user.id, 'LOGIN_FAILED', null, ipAddress);
    throw new AppError(401, 'INVALID_CREDENTIALS', 'Email or password is incorrect.');
  }

  if (!user.isActive) {
    throw new AppError(403, 'ACCOUNT_DISABLED', 'This account has been disabled.');
  }

  const { device: deviceRecord, isNewDevice } = await deviceService.upsertDevice(user.id, device);
  const tokens = await tokenService.issueTokenPair(user.id, deviceRecord.id, ipAddress);

  await writeAuditLog(user.id, 'LOGIN_SUCCESS', { deviceId: device.deviceId }, ipAddress);

  if (isNewDevice) {
    await writeAuditLog(user.id, 'NEW_DEVICE_LOGIN', { deviceId: device.deviceId }, ipAddress);
    const otherDevices = await deviceService.listUserDevices(user.id, device.deviceId);
    if (otherDevices.length > 0) {
      await notificationService.sendSecurityAlert(user.id, {
        title: 'New login detected',
        body: `A new ${device.platform} device just signed in to your account.`,
        data: { type: 'NEW_DEVICE_LOGIN' },
      });
    }
  }

  return { user: toPublicUser(user), ...tokens };
}

async function refresh({ refreshToken }, ipAddress) {
  return tokenService.rotateRefreshToken(refreshToken, ipAddress);
}

async function logout({ refreshToken }) {
  await tokenService.revokeRefreshToken(refreshToken);
}

async function logoutAll({ userId }) {
  await tokenService.revokeAllUserTokens(userId);
}

async function setPin({ userId, pin }) {
  if (!PIN_REGEX.test(pin)) {
    throw new AppError(400, 'VALIDATION_ERROR', 'PIN must be exactly 6 digits.');
  }
  const pinHash = await hashPassword(pin);
  await prisma.user.update({ where: { id: userId }, data: { pinHash } });
}

async function verifyPin({ userId, pin }) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user || !user.pinHash || !(await comparePassword(pin, user.pinHash))) {
    throw new AppError(401, 'INVALID_PIN', 'Incorrect PIN.');
  }
}

async function reportPinLockout({ userId, deviceId }, ipAddress) {
  await writeAuditLog(userId, 'PIN_LOCKOUT', { deviceId }, ipAddress);
  await notificationService.sendSecurityAlert(userId, {
    title: 'Too many incorrect PIN attempts',
    body: 'Your session was locked after 5 incorrect PIN attempts.',
    data: { type: 'PIN_LOCKOUT' },
  });
}

async function forgotPassword({ email }) {
  const normalizedEmail = email.trim().toLowerCase();
  const user = await prisma.user.findUnique({ where: { email: normalizedEmail } });

  if (user) {
    const otp = await otpService.issueOtp(user.id);
    await emailService.sendOtpEmail(user.email, otp);
    await writeAuditLog(user.id, 'PASSWORD_RESET_REQUESTED', null, null);
  }
  // Response is identical whether or not the account exists — prevents email enumeration.
}

async function resetPassword({ email, otp, newPassword }) {
  const normalizedEmail = email.trim().toLowerCase();
  const user = await prisma.user.findUnique({ where: { email: normalizedEmail } });

  if (!user) {
    throw new AppError(400, 'OTP_INVALID_OR_EXPIRED', 'Invalid or expired OTP.');
  }

  await otpService.verifyOtp(user.id, otp);

  const passwordHash = await hashPassword(newPassword);
  await prisma.user.update({ where: { id: user.id }, data: { passwordHash } });
  await tokenService.revokeAllUserTokens(user.id);

  await writeAuditLog(user.id, 'PASSWORD_RESET_SUCCESS', null, null);
  await notificationService.sendSecurityAlert(user.id, {
    title: 'Password changed',
    body: 'Your password was reset. You have been logged out of all devices.',
    data: { type: 'PASSWORD_RESET_SUCCESS' },
  });
}

async function checkSession({ userId }) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user || !user.isActive) {
    throw new AppError(401, 'TOKEN_INVALID', 'Session is no longer valid.');
  }
  return toPublicUser(user);
}

async function updateDeviceFcmToken({ userId, deviceId, fcmToken }) {
  await deviceService.updateFcmToken(userId, deviceId, fcmToken);
}

async function logSuspiciousLoginAttempt(email, ipAddress) {
  const normalizedEmail = email ? email.trim().toLowerCase() : null;
  const user = normalizedEmail
    ? await prisma.user.findUnique({ where: { email: normalizedEmail } })
    : null;

  await writeAuditLog(user ? user.id : null, 'SUSPICIOUS_LOGIN_ATTEMPT', { email: normalizedEmail }, ipAddress);

  if (user) {
    const devices = await deviceService.listUserDevices(user.id);
    if (devices.length > 0) {
      await notificationService.sendSecurityAlert(user.id, {
        title: 'Suspicious login activity',
        body: 'Multiple failed login attempts were detected on your account.',
        data: { type: 'SUSPICIOUS_LOGIN_ATTEMPT' },
      });
    }
  }
}

module.exports = {
  register,
  login,
  refresh,
  logout,
  logoutAll,
  setPin,
  verifyPin,
  reportPinLockout,
  forgotPassword,
  resetPassword,
  checkSession,
  updateDeviceFcmToken,
  logSuspiciousLoginAttempt,
};
