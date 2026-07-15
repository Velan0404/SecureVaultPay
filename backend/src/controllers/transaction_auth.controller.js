const transactionAuthService = require('../services/transaction_auth.service');
const catchAsync = require('../utils/catchAsync');

const setPhoneNumber = catchAsync(async (req, res) => {
  const result = await transactionAuthService.setPhoneNumber({ userId: req.user.id, phoneNumber: req.body.phoneNumber });
  res.status(200).json({ success: true, data: result });
});

const start = catchAsync(async (req, res) => {
  const result = await transactionAuthService.startSession({ userId: req.user.id, ...req.body }, req.ip);
  res.status(201).json({ success: true, data: result });
});

const confirmFingerprint = catchAsync(async (req, res) => {
  const result = await transactionAuthService.confirmFingerprint(
    { userId: req.user.id, sessionId: req.params.sessionId },
    req.ip,
  );
  res.status(200).json({ success: true, data: result });
});

const recordFingerprintFailure = catchAsync(async (req, res) => {
  await transactionAuthService.recordFingerprintFailure(
    { userId: req.user.id, sessionId: req.params.sessionId, attemptNumber: Number(req.body.attemptNumber) || 1 },
    req.ip,
  );
  res.status(200).json({ success: true, data: { message: 'Recorded.' } });
});

const sendOtp = catchAsync(async (req, res) => {
  const result = await transactionAuthService.sendOtp({ userId: req.user.id, sessionId: req.params.sessionId }, req.ip);
  res.status(200).json({ success: true, data: result });
});

const verifyOtp = catchAsync(async (req, res) => {
  const result = await transactionAuthService.verifyOtp(
    { userId: req.user.id, sessionId: req.params.sessionId, code: req.body.code },
    req.ip,
  );
  res.status(200).json({ success: true, data: result });
});

module.exports = { setPhoneNumber, start, confirmFingerprint, recordFingerprintFailure, sendOtp, verifyOtp };
