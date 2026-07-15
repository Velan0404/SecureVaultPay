const { rateLimit, ipKeyGenerator } = require('express-rate-limit');
const authService = require('../services/auth.service');

function emailKeyGenerator(req) {
  const email = req.body && req.body.email ? String(req.body.email).trim().toLowerCase() : 'unknown';
  return `${ipKeyGenerator(req.ip)}:${email}`;
}

// Transaction Authentication runs behind `authenticate`, so req.user.id is
// always present — keying by user (not IP) means the limit follows the
// account regardless of network/NAT.
function userKeyGenerator(req) {
  return req.user ? req.user.id : ipKeyGenerator(req.ip);
}

function rateLimitedResponse(req, res, next, options) {
  res.status(options.statusCode).json({
    success: false,
    error: { code: 'RATE_LIMITED', message: 'Too many requests. Please try again later.' },
  });
}

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 5,
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: true,
  keyGenerator: emailKeyGenerator,
  handler: async (req, res, next, options) => {
    await authService.logSuspiciousLoginAttempt(req.body && req.body.email, req.ip);
    rateLimitedResponse(req, res, next, options);
  },
});

const registerLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  limit: 10,
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitedResponse,
});

const forgotPasswordLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  limit: 3,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: emailKeyGenerator,
  handler: rateLimitedResponse,
});

const resetPasswordLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  limit: 5,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: emailKeyGenerator,
  handler: rateLimitedResponse,
});

const pinVerifyLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 5,
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: true,
  handler: rateLimitedResponse,
});

const refreshLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  limit: 30,
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitedResponse,
});

const walletTransferLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitedResponse,
});

const demoMoneyLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  limit: 5,
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitedResponse,
});

// Transaction Authentication (Main Wallet transfer security layer).
const transactionAuthStartLimiter = rateLimit({
  windowMs: 24 * 60 * 60 * 1000,
  limit: 10,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: userKeyGenerator,
  handler: rateLimitedResponse,
});

const otpSendLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  limit: 3,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: userKeyGenerator,
  handler: rateLimitedResponse,
});

// A coarse backstop across all sessions — the real 5-attempt cap per session
// lives in transaction_auth.service.js's own otpAttempts tracking.
const otpVerifyLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  limit: 20,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: userKeyGenerator,
  handler: rateLimitedResponse,
});

module.exports = {
  loginLimiter,
  registerLimiter,
  forgotPasswordLimiter,
  resetPasswordLimiter,
  pinVerifyLimiter,
  refreshLimiter,
  walletTransferLimiter,
  demoMoneyLimiter,
  transactionAuthStartLimiter,
  otpSendLimiter,
  otpVerifyLimiter,
};
