const express = require('express');
const transactionAuthController = require('../controllers/transaction_auth.controller');
const authenticate = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate.middleware');
const {
  transactionAuthStartLimiter,
  otpSendLimiter,
  otpVerifyLimiter,
} = require('../middlewares/rateLimit.middleware');
const { phoneSchema, startSchema, otpVerifySchema } = require('../utils/transactionAuth.validation');

const router = express.Router();

// Every route here requires a valid session (JWT), same as the Wallet
// module — this feature is an additional layer on top of existing
// authentication, not a replacement for it.
router.use(authenticate);

router.patch('/phone', validate(phoneSchema), transactionAuthController.setPhoneNumber);

router.post('/start', transactionAuthStartLimiter, validate(startSchema), transactionAuthController.start);

router.post('/:sessionId/confirm-fingerprint', transactionAuthController.confirmFingerprint);
router.post('/:sessionId/fingerprint-failed', transactionAuthController.recordFingerprintFailure);

router.post('/:sessionId/otp/send', otpSendLimiter, transactionAuthController.sendOtp);

router.post(
  '/:sessionId/otp/verify',
  otpVerifyLimiter,
  validate(otpVerifySchema),
  transactionAuthController.verifyOtp,
);

module.exports = router;
