const { z } = require('zod');

const phoneSchema = z.object({
  phoneNumber: z.string().regex(/^\+[1-9]\d{7,14}$/, 'Enter a phone number in international format, e.g. +919876543210.'),
});

const startSchema = z.object({
  deviceId: z.string().min(1, 'deviceId is required.'),
  purposeWalletId: z.string().uuid('Invalid wallet id.'),
  amount: z
    .string()
    .regex(/^\d+(\.\d{1,2})?$/, 'Must be a valid amount with up to 2 decimal places.')
    .refine((value) => Number(value) > 0, 'Amount must be greater than zero.'),
});

const otpVerifySchema = z.object({
  code: z.string().regex(/^\d{4,10}$/, 'Enter the verification code.'),
});

module.exports = { phoneSchema, startSchema, otpVerifySchema };
