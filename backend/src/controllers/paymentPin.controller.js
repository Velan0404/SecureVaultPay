const paymentPinService = require('../services/paymentPin.service');
const catchAsync = require('../utils/catchAsync');

// Read before "Review Payment -> Continue" so the client knows whether to
// show Create Payment PIN or Enter Payment PIN next.
const status = catchAsync(async (req, res) => {
  const hasPaymentPin = await paymentPinService.hasPaymentPin(req.user.id);
  res.status(200).json({ success: true, data: { hasPaymentPin } });
});

const create = catchAsync(async (req, res) => {
  await paymentPinService.createPaymentPin({ userId: req.user.id, pin: req.body.pin });
  res.status(201).json({ success: true, data: { message: 'Payment PIN created.' } });
});

module.exports = { status, create };
