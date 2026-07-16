const { z } = require('zod');

const PAYMENT_TYPES = [
  'RENT',
  'ELECTRICITY',
  'WATER',
  'INTERNET',
  'MOBILE_RECHARGE',
  'SUBSCRIPTION',
  'EMI',
  'INSURANCE',
  'SAVINGS',
  'CUSTOM',
];

const FREQUENCIES = ['DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY', 'CUSTOM'];

const amountSchema = z
  .string()
  .regex(/^\d+(\.\d{1,2})?$/, 'Must be a valid amount with up to 2 decimal places.')
  .refine((value) => Number(value) > 0, 'Amount must be greater than zero.');

// Verified by requirePaymentPin (paymentPin.middleware.js) and stripped from
// req.body before the controller runs — same Payment PIN as every other
// payment module, required only at creation/editing, never at automatic
// execution time.
const paymentPinField = z.string().regex(/^\d{6}$/, 'PIN must be exactly 6 digits.');

const createScheduledPaymentSchema = z
  .object({
    title: z.string().trim().min(1, 'Title is required.').max(60, 'Title must be 60 characters or fewer.'),
    paymentType: z.enum(PAYMENT_TYPES),
    amount: amountSchema,
    frequency: z.enum(FREQUENCIES),
    customIntervalDays: z.number().int().min(1).max(365).optional(),
    purposeWalletId: z.string().uuid('Invalid wallet id.'),
    merchantId: z.string().uuid('Invalid merchant id.').optional(),
    receiverUserId: z.string().uuid('Invalid receiver id.').optional(),
    note: z.string().max(140, 'Note must be 140 characters or fewer.').optional(),
    startDate: z.string().datetime({ message: 'startDate must be an ISO date-time.' }),
    endDate: z.string().datetime({ message: 'endDate must be an ISO date-time.' }).optional(),
    paymentPin: paymentPinField,
  })
  .refine((data) => Boolean(data.merchantId) !== Boolean(data.receiverUserId), {
    message: 'Provide exactly one of merchantId or receiverUserId.',
    path: ['merchantId'],
  })
  .refine((data) => data.frequency !== 'CUSTOM' || typeof data.customIntervalDays === 'number', {
    message: 'customIntervalDays is required when frequency is CUSTOM.',
    path: ['customIntervalDays'],
  });

// The destination (merchantId/receiverUserId) and paymentType are
// deliberately not editable here — see scheduledPayment.service.js's
// update() for why.
const updateScheduledPaymentSchema = z
  .object({
    title: z.string().trim().min(1).max(60).optional(),
    amount: amountSchema.optional(),
    frequency: z.enum(FREQUENCIES).optional(),
    customIntervalDays: z.number().int().min(1).max(365).optional(),
    endDate: z.string().datetime().nullable().optional(),
    note: z.string().max(140).optional(),
    purposeWalletId: z.string().uuid().optional(),
    paymentPin: paymentPinField,
  })
  .refine((data) => data.frequency !== 'CUSTOM' || typeof data.customIntervalDays === 'number', {
    message: 'customIntervalDays is required when frequency is CUSTOM.',
    path: ['customIntervalDays'],
  });

module.exports = { PAYMENT_TYPES, FREQUENCIES, createScheduledPaymentSchema, updateScheduledPaymentSchema };
