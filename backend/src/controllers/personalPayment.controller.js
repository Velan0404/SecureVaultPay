const personalPaymentService = require('../services/personalPayment.service');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/appError');
const { phoneNumberSchema } = require('../utils/auth.validation');

const getMyQr = catchAsync(async (req, res) => {
  const qr = await personalPaymentService.getMyQr(req.user.id);
  res.status(200).json({ success: true, data: qr });
});

// The shared `validate` middleware only validates req.body, so — same
// precedent as listMerchants' `category` query param — the `phone` query
// param is validated inline here, against the exact same international-
// format rule registration enforces.
const searchByPhone = catchAsync(async (req, res) => {
  const result = phoneNumberSchema.safeParse(req.query.phone);
  if (!result.success) {
    throw new AppError(400, 'VALIDATION_ERROR', 'Enter a mobile number in international format, e.g. +919876543210.');
  }
  const receiver = await personalPaymentService.searchByPhone(result.data);
  res.status(200).json({ success: true, data: { receiver } });
});

const lookupReceiver = catchAsync(async (req, res) => {
  const receiver = await personalPaymentService.lookupReceiver({
    userId: req.params.userId,
    secureVaultId: req.query.secureVaultId,
  });
  res.status(200).json({ success: true, data: { receiver } });
});

// requirePaymentPin has already verified the Payment PIN and stripped it
// from req.body by the time this runs — no fingerprint/OTP session involved.
const pay = catchAsync(async (req, res) => {
  const payment = await personalPaymentService.pay(
    req.user.id,
    {
      receiverId: req.params.receiverId,
      purposeWalletId: req.body.purposeWalletId,
      amount: req.body.amount,
      note: req.body.note,
    },
    req.ip,
  );
  res.status(200).json({ success: true, data: { payment } });
});

module.exports = { getMyQr, searchByPhone, lookupReceiver, pay };
