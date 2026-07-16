const express = require('express');
const qrController = require('../controllers/qr.controller');
const authenticate = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate.middleware');
const requirePaymentPin = require('../middlewares/paymentPin.middleware');
const { qrGenerateLimiter, qrValidateLimiter, paymentPinVerifyLimiter } = require('../middlewares/rateLimit.middleware');
const { generateDemoQrSchema, payQrSchema } = require('../utils/qr.validation');

const router = express.Router();

// Every QR endpoint is user-scoped and private, same as Wallet/Merchant.
router.use(authenticate);

router.post('/demo', qrGenerateLimiter, validate(generateDemoQrSchema), qrController.generateDemo);
router.get('/validate/:qrId', qrValidateLimiter, qrController.validate);

// Same ordering discipline as merchant.routes.js's /:id/pay: validate() runs
// first so `paymentPin` is confirmed well-formed before requirePaymentPin
// verifies it against the stored hash and strips it from req.body. No
// biometric/OTP involved — same Payment PIN introduced in Phase 5.1.
router.post(
  '/:qrId/pay',
  paymentPinVerifyLimiter,
  validate(payQrSchema),
  requirePaymentPin,
  qrController.pay,
);

module.exports = router;
