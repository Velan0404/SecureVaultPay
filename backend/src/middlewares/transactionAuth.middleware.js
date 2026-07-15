const transactionAuthService = require('../services/transaction_auth.service');
const AppError = require('../utils/appError');

// Guard for the Wallet Transfer route — wallet.routes.js/controller.js/
// service.js are untouched. Requires the client to have already completed
// fingerprint + Twilio OTP verification for this exact wallet + amount (see
// transaction_auth.service), then observes the unmodified controller's
// response to write the required audit trail and send the success push —
// all without wallet.controller.js knowing this layer exists.
async function requireTransactionAuth(req, res, next) {
  const { transactionAuthSessionId, purposeWalletId, amount } = req.body;

  if (!transactionAuthSessionId || typeof transactionAuthSessionId !== 'string') {
    return next(
      new AppError(403, 'TRANSACTION_AUTH_REQUIRED', 'Complete fingerprint and OTP verification before continuing.'),
    );
  }

  let session;
  try {
    session = await transactionAuthService.claimVerifiedSession({
      userId: req.user.id,
      sessionId: transactionAuthSessionId,
      purposeWalletId,
      amount,
    });
  } catch (err) {
    return next(err);
  }

  // Capture the resulting transfer id from the (unmodified) controller's
  // JSON response for the audit log, without altering what's actually sent
  // to the client.
  let capturedId;
  const originalJson = res.json.bind(res);
  res.json = (body) => {
    capturedId = body?.data?.transfer?.id;
    return originalJson(body);
  };

  res.on('finish', () => {
    const success = res.statusCode >= 200 && res.statusCode < 300;
    const outcome = transactionAuthService.recordTransferOutcome(
      {
        userId: req.user.id,
        deviceId: session.deviceId,
        sessionId: transactionAuthSessionId,
        purposeWalletId,
        amount,
        transactionId: capturedId,
        success,
      },
      req.ip,
    );

    outcome.catch((err) => console.error('[TransactionAuthMiddleware] Failed to record outcome:', err.message));
  });

  next();
}

module.exports = requireTransactionAuth;
