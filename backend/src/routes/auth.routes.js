const express = require('express');
const authController = require('../controllers/auth.controller');
const authenticate = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate.middleware');
const {
  loginLimiter,
  registerLimiter,
  forgotPasswordLimiter,
  resetPasswordLimiter,
  pinVerifyLimiter,
  refreshLimiter,
} = require('../middlewares/rateLimit.middleware');
const {
  registerSchema,
  loginSchema,
  refreshSchema,
  logoutSchema,
  pinSetSchema,
  pinVerifySchema,
  pinLockoutReportSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  fcmTokenUpdateSchema,
} = require('../utils/auth.validation');

const router = express.Router();

router.post('/register', registerLimiter, validate(registerSchema), authController.register);
router.post('/login', loginLimiter, validate(loginSchema), authController.login);
router.post('/refresh', refreshLimiter, validate(refreshSchema), authController.refresh);
router.post('/logout', validate(logoutSchema), authController.logout);
router.post('/logout-all', authenticate, authController.logoutAll);

router.post('/pin/set', authenticate, validate(pinSetSchema), authController.setPin);
router.post('/pin/verify', authenticate, pinVerifyLimiter, validate(pinVerifySchema), authController.verifyPin);
router.post(
  '/pin/lockout-report',
  authenticate,
  validate(pinLockoutReportSchema),
  authController.pinLockoutReport,
);

router.post(
  '/forgot-password',
  forgotPasswordLimiter,
  validate(forgotPasswordSchema),
  authController.forgotPassword,
);
router.post(
  '/reset-password',
  resetPasswordLimiter,
  validate(resetPasswordSchema),
  authController.resetPassword,
);

router.get('/check-session', authenticate, authController.checkSession);
router.patch(
  '/device/fcm-token',
  authenticate,
  validate(fcmTokenUpdateSchema),
  authController.updateFcmToken,
);

module.exports = router;
