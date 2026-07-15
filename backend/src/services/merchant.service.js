const { Prisma } = require('../generated/prisma');
const AppError = require('../utils/appError');
const repository = require('../repositories/merchant.repository');
const walletService = require('./wallet.service');
const notificationService = require('./notification.service');

function toPublicMerchant(merchant) {
  return {
    id: merchant.id,
    merchantName: merchant.merchantName,
    merchantCategory: merchant.merchantCategory,
    merchantCode: merchant.merchantCode,
    merchantLogo: merchant.merchantLogo,
    status: merchant.status,
    createdAt: merchant.createdAt,
  };
}

async function listMerchants({ category } = {}) {
  const merchants = await repository.listActive({ category });
  return merchants.map(toPublicMerchant);
}

async function getMerchant(merchantId) {
  const merchant = await repository.findById(merchantId);
  if (!merchant) {
    throw new AppError(404, 'MERCHANT_NOT_FOUND', 'Merchant not found.');
  }
  return toPublicMerchant(merchant);
}

// Called only after requirePaymentPin (paymentPin.middleware.js) has already
// verified the caller's Payment PIN — never directly reachable without it.
async function pay(userId, { merchantId, purposeWalletId, amount }, ipAddress) {
  const amountDecimal = new Prisma.Decimal(amount);
  if (amountDecimal.lessThanOrEqualTo(0)) {
    throw new AppError(400, 'INVALID_AMOUNT', 'Amount must be greater than zero.');
  }

  const merchant = await repository.findById(merchantId);
  if (!merchant) {
    throw new AppError(404, 'MERCHANT_NOT_FOUND', 'Merchant not found.');
  }
  if (merchant.status !== 'ACTIVE') {
    throw new AppError(400, 'MERCHANT_INACTIVE', 'This merchant is not available for payment.');
  }

  // Reuses the Wallet module's own ownership + active-status check — Main
  // Wallet is never a valid source here since this only ever accepts a
  // Purpose Wallet id, and wallet.service.js is never modified by this call.
  const wallet = await walletService.getPurposeWallet(userId, purposeWalletId);
  if (wallet.status !== 'ACTIVE') {
    throw new AppError(400, 'WALLET_ARCHIVED', 'Cannot pay from an archived wallet.');
  }

  const result = await repository.executePayment({
    userId,
    purposeWalletId,
    purposeWalletName: wallet.name,
    merchantId,
    merchantName: merchant.merchantName,
    amount: amountDecimal,
  });

  if (!result.success) {
    throw new AppError(400, 'INSUFFICIENT_BALANCE', 'Purpose wallet balance is insufficient for this payment.');
  }

  await repository.writeAuditLog(
    userId,
    'MERCHANT_PAYMENT_SUCCESS',
    { paymentId: result.payment.id, purposeWalletId, merchantId, amount: result.payment.amount },
    ipAddress,
  );

  try {
    await notificationService.sendPushNotification(userId, {
      title: 'Payment Successful',
      body: `₹${amount} paid to ${merchant.merchantName} from ${wallet.name}.`,
      data: { type: 'MERCHANT_PAYMENT_SUCCESS', paymentId: result.payment.id, purposeWalletId, merchantId },
    });
  } catch (err) {
    // Best-effort — a notification failure must never surface as a payment
    // failure to the user; the payment itself already succeeded.
    console.error('[MerchantService] Failed to send payment notification:', err.message);
  }

  return {
    id: result.payment.id,
    purposeWalletId,
    merchantId,
    merchantName: merchant.merchantName,
    amount: result.payment.amount,
    createdAt: result.payment.createdAt,
  };
}

async function getTotalSpent(userId) {
  const total = await repository.sumUserSpending(userId);
  return total ?? new Prisma.Decimal(0);
}

module.exports = { listMerchants, getMerchant, pay, getTotalSpent };
