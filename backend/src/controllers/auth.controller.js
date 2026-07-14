const authService = require('../services/auth.service');
const catchAsync = require('../utils/catchAsync');

const register = catchAsync(async (req, res) => {
  const result = await authService.register(req.body, req.ip);
  res.status(201).json({ success: true, data: result });
});

const login = catchAsync(async (req, res) => {
  const result = await authService.login(req.body, req.ip);
  res.status(200).json({ success: true, data: result });
});

const refresh = catchAsync(async (req, res) => {
  const result = await authService.refresh(req.body, req.ip);
  res.status(200).json({ success: true, data: result });
});

const logout = catchAsync(async (req, res) => {
  await authService.logout(req.body);
  res.status(200).json({ success: true, data: { message: 'Logged out successfully.' } });
});

const logoutAll = catchAsync(async (req, res) => {
  await authService.logoutAll({ userId: req.user.id });
  res.status(200).json({ success: true, data: { message: 'Logged out of all devices.' } });
});

const setPin = catchAsync(async (req, res) => {
  await authService.setPin({ userId: req.user.id, pin: req.body.pin });
  res.status(200).json({ success: true, data: { message: 'PIN set successfully.' } });
});

const verifyPin = catchAsync(async (req, res) => {
  await authService.verifyPin({ userId: req.user.id, pin: req.body.pin });
  res.status(200).json({ success: true, data: { message: 'PIN verified.' } });
});

const pinLockoutReport = catchAsync(async (req, res) => {
  await authService.reportPinLockout({ userId: req.user.id, deviceId: req.body.deviceId }, req.ip);
  res.status(200).json({ success: true, data: { message: 'Lockout recorded.' } });
});

const forgotPassword = catchAsync(async (req, res) => {
  await authService.forgotPassword(req.body);
  res.status(200).json({
    success: true,
    data: { message: 'If that email exists, a password reset code has been sent.' },
  });
});

const resetPassword = catchAsync(async (req, res) => {
  await authService.resetPassword(req.body);
  res.status(200).json({
    success: true,
    data: { message: 'Password reset successful. Please log in again.' },
  });
});

const checkSession = catchAsync(async (req, res) => {
  const user = await authService.checkSession({ userId: req.user.id });
  res.status(200).json({ success: true, data: { user } });
});

const updateFcmToken = catchAsync(async (req, res) => {
  await authService.updateDeviceFcmToken({
    userId: req.user.id,
    deviceId: req.body.deviceId,
    fcmToken: req.body.fcmToken,
  });
  res.status(200).json({ success: true, data: { message: 'FCM token updated.' } });
});

module.exports = {
  register,
  login,
  refresh,
  logout,
  logoutAll,
  setPin,
  verifyPin,
  pinLockoutReport,
  forgotPassword,
  resetPassword,
  checkSession,
  updateFcmToken,
};
