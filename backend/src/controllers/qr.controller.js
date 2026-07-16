const qrService = require('../services/qr.service');
const catchAsync = require('../utils/catchAsync');

const generateDemo = catchAsync(async (req, res) => {
  const qr = await qrService.generateDemo(req.body.merchantId);
  res.status(201).json({ success: true, data: qr });
});

const validate = catchAsync(async (req, res) => {
  const result = await qrService.validate(req.params.qrId);
  res.status(200).json({ success: true, data: result });
});

// requirePaymentPin has already verified the Payment PIN and stripped it
// from req.body by the time this runs.
const pay = catchAsync(async (req, res) => {
  const payment = await qrService.pay(
    req.user.id,
    { qrId: req.params.qrId, purposeWalletId: req.body.purposeWalletId, amount: req.body.amount },
    req.ip,
  );
  res.status(200).json({ success: true, data: { payment } });
});

module.exports = { generateDemo, validate, pay };
