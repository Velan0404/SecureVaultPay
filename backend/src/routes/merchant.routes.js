const express = require('express');
const merchantController = require('../controllers/merchant.controller');
const authenticate = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate.middleware');
const requirePaymentPin = require('../middlewares/paymentPin.middleware');
const { paymentPinVerifyLimiter } = require('../middlewares/rateLimit.middleware');
const { payMerchantSchema } = require('../utils/merchant.validation');

const router = express.Router();

// Every merchant endpoint is user-scoped and private, same as Wallet.
router.use(authenticate);

// The `category` query param (optional) is validated inline in the
// controller — the shared `validate` middleware only validates req.body,
// and is left untouched rather than widened for this one query-string case.
router.get('/', merchantController.listMerchants);
router.get('/spending/total', merchantController.getTotalSpent);
router.get('/:id', merchantController.getMerchant);

// validate() runs first so `paymentPin` is confirmed to be a well-formed
// 6-digit string before requirePaymentPin verifies it against the stored
// hash and strips it from req.body — merchant payments no longer require
// fingerprint + Twilio OTP (Phase 5.1); that flow remains in place for
// Main Wallet -> Purpose Wallet transfers only (see transactionAuth.middleware.js).
router.post(
  '/:id/pay',
  paymentPinVerifyLimiter,
  validate(payMerchantSchema),
  requirePaymentPin,
  merchantController.pay,
);

module.exports = router;
