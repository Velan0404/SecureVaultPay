const { z } = require('zod');

const CATEGORIES = [
  'GROCERY',
  'FOOD',
  'FUEL',
  'SHOPPING',
  'ENTERTAINMENT',
  'HEALTHCARE',
  'EDUCATION',
  'UTILITY',
  'TRAVEL',
  'OTHER',
];

const payMerchantSchema = z.object({
  purposeWalletId: z.string().uuid('Invalid wallet id.'),
  amount: z
    .string()
    .regex(/^\d+(\.\d{1,2})?$/, 'Must be a valid amount with up to 2 decimal places.')
    .refine((value) => Number(value) > 0, 'Amount must be greater than zero.'),
  // Verified by requirePaymentPin (paymentPin.middleware.js) and stripped
  // from req.body before this route's controller ever runs — merchant
  // payments no longer require fingerprint + Twilio OTP (Phase 5.1).
  paymentPin: z.string().regex(/^\d{6}$/, 'PIN must be exactly 6 digits.'),
});

module.exports = { CATEGORIES, payMerchantSchema };
