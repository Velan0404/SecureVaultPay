const merchantService = require('../services/merchant.service');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/appError');
const { CATEGORIES } = require('../utils/merchant.validation');

const listMerchants = catchAsync(async (req, res) => {
  const { category } = req.query;
  if (category !== undefined && !CATEGORIES.includes(category)) {
    throw new AppError(400, 'VALIDATION_ERROR', `category must be one of: ${CATEGORIES.join(', ')}.`);
  }
  const merchants = await merchantService.listMerchants({ category });
  res.status(200).json({ success: true, data: { merchants } });
});

const getMerchant = catchAsync(async (req, res) => {
  const merchant = await merchantService.getMerchant(req.params.id);
  res.status(200).json({ success: true, data: { merchant } });
});

// requirePaymentPin has already verified the Payment PIN and stripped it
// from req.body by the time this runs — no fingerprint/OTP session involved.
const pay = catchAsync(async (req, res) => {
  const payment = await merchantService.pay(
    req.user.id,
    {
      merchantId: req.params.id,
      purposeWalletId: req.body.purposeWalletId,
      amount: req.body.amount,
    },
    req.ip,
  );
  res.status(200).json({ success: true, data: { payment } });
});

// A dedicated endpoint rather than extending the Wallet dashboard response —
// keeps wallet.service.js/controller.js untouched, per this phase's scope.
const getTotalSpent = catchAsync(async (req, res) => {
  const totalSpent = await merchantService.getTotalSpent(req.user.id);
  res.status(200).json({ success: true, data: { totalSpent } });
});

module.exports = { listMerchants, getMerchant, pay, getTotalSpent };
