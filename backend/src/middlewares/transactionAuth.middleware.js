const transactionAuthService = require('../services/transaction_auth.service');
const AppError = require('../utils/appError');

// Inserted into the Wallet Transfer route only — everything else about
// wallet.routes.js/controller.js/service.js/repository.js is untouched.
// Requires the client to have already completed fingerprint + Twilio OTP
// verification for this exact wallet + amount (see transaction_auth.service),
// then observes the (unmodified) transfer controller's response to write the
// required audit trail and send the "Transfer Successful" push — all without
// the wallet module knowing this layer exists.
async function requireTransactionAuth(req, res, next) {
  const { transactionAuthSessionId, purposeWalletId, amount } = req.body;

  if (!transactionAuthSessionId || typeof transactionAuthSessionId !== 'string') {
    return next(
      new AppError(403, 'TRANSACTION_AUTH_REQUIRED', 'Complete fingerprint and OTP verification before transferring.'),
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

  // Capture the transfer id from the (unmodified) controller's JSON response
  // for the audit log, without altering what's actually sent to the client.
  let capturedTransactionId;
  const originalJson = res.json.bind(res);
  res.json = (body) => {
    capturedTransactionId = body?.data?.transfer?.id;
    return originalJson(body);
  };

  res.on('finish', () => {
    transactionAuthService
      .recordTransferOutcome(
        {
          userId: req.user.id,
          deviceId: session.deviceId,
          sessionId: transactionAuthSessionId,
          purposeWalletId,
          amount,
          transactionId: capturedTransactionId,
          success: res.statusCode >= 200 && res.statusCode < 300,
        },
        req.ip,
      )
      .catch((err) => console.error('[TransactionAuthMiddleware] Failed to record transfer outcome:', err.message));
  });

  next();
}

module.exports = requireTransactionAuth;
