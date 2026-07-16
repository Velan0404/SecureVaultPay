const { z } = require('zod');
const { payMerchantSchema } = require('./merchant.validation');

const generateDemoQrSchema = z.object({
  merchantId: z.string().uuid('Invalid merchant id.'),
});

// Identical shape to payMerchantSchema (purposeWalletId, amount, paymentPin)
// — reused as-is rather than redeclared, since a QR payment authorizes
// exactly the same request shape as a tap-to-pay merchant payment.
const payQrSchema = payMerchantSchema;

module.exports = { generateDemoQrSchema, payQrSchema };
