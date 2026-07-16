const express = require('express');
const personalPaymentController = require('../controllers/personalPayment.controller');
const authenticate = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate.middleware');
const requirePaymentPin = require('../middlewares/paymentPin.middleware');
const {
  paymentPinVerifyLimiter,
  personalPaymentLookupLimiter,
  personalPaymentSearchLimiter,
} = require('../middlewares/rateLimit.middleware');
const { payPersonalSchema } = require('../utils/personalPayment.validation');

const router = express.Router();

// Every Personal Payment endpoint is user-scoped and private, same as
// Wallet/Merchant/QR.
router.use(authenticate);

router.get('/my-qr', personalPaymentController.getMyQr);
// Phase 7.1 — Dashboard "Pay" (Person -> Person by mobile number). No path
// collision risk with /:receiverId/pay below: different HTTP method, and
// this router has no other single-segment GET route for /search to shadow.
router.get('/search', personalPaymentSearchLimiter, personalPaymentController.searchByPhone);
router.get('/lookup/:userId', personalPaymentLookupLimiter, personalPaymentController.lookupReceiver);

// Same ordering discipline as merchant.routes.js's /:id/pay: validate() runs
// first so `paymentPin` is confirmed well-formed before requirePaymentPin
// verifies it against the stored hash and strips it from req.body. No
// biometric/OTP involved — same Payment PIN introduced in Phase 5.1.
router.post(
  '/:receiverId/pay',
  paymentPinVerifyLimiter,
  validate(payPersonalSchema),
  requirePaymentPin,
  personalPaymentController.pay,
);

module.exports = router;
