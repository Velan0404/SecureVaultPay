const { z } = require('zod');

const payPersonalSchema = z.object({
  purposeWalletId: z.string().uuid('Invalid wallet id.'),
  amount: z
    .string()
    .regex(/^\d+(\.\d{1,2})?$/, 'Must be a valid amount with up to 2 decimal places.')
    .refine((value) => Number(value) > 0, 'Amount must be greater than zero.'),
  note: z.string().max(140, 'Note must be 140 characters or fewer.').optional(),
  // Verified by requirePaymentPin (paymentPin.middleware.js) and stripped
  // from req.body before this route's controller ever runs — Personal
  // Payment uses the same Payment PIN as Merchant/QR payments, no
  // fingerprint/OTP.
  paymentPin: z.string().regex(/^\d{6}$/, 'PIN must be exactly 6 digits.'),
});

module.exports = { payPersonalSchema };
