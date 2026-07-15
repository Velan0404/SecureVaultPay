const paymentPinService = require('../services/paymentPin.service');
const AppError = require('../utils/appError');

// Guards the Merchant Payment route only — verifies the Payment PIN
// server-side on every payment (never a client-cached/local-only check,
// since this authorizes real money movement, unlike the App PIN's routine
// unlock). Strips the raw PIN from req.body once verified, so nothing
// downstream (controller, service, logs) ever sees or persists it.
async function requirePaymentPin(req, res, next) {
  const { paymentPin } = req.body;

  if (!paymentPin || typeof paymentPin !== 'string') {
    return next(new AppError(403, 'PAYMENT_PIN_REQUIRED', 'Enter your Payment PIN to authorize this payment.'));
  }

  try {
    await paymentPinService.verifyPaymentPin({ userId: req.user.id, pin: paymentPin });
  } catch (err) {
    return next(err);
  }

  delete req.body.paymentPin;
  next();
}

module.exports = requirePaymentPin;
