const { z } = require('zod');

// Amounts travel as decimal strings, not JSON numbers, so they can be handed
// straight to Prisma's Decimal type without ever passing through a JS float.
function decimalString({ positive = false } = {}) {
  return z
    .string()
    .regex(/^\d+(\.\d{1,2})?$/, 'Must be a valid amount with up to 2 decimal places.')
    .refine((value) => (positive ? Number(value) > 0 : true), 'Amount must be greater than zero.');
}

const createPurposeWalletSchema = z.object({
  name: z.string().min(1, 'Name is required.').max(50, 'Name must be 50 characters or fewer.'),
  icon: z.string().min(1, 'Icon is required.'),
  color: z.string().regex(/^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$/, 'Color must be a hex code, e.g. #E53935.'),
  purpose: z.string().max(200).optional(),
  spendingLimit: decimalString({ positive: true }).optional(),
});

const updatePurposeWalletSchema = createPurposeWalletSchema.partial();

const transferSchema = z.object({
  purposeWalletId: z.string().uuid('Invalid wallet id.'),
  amount: decimalString({ positive: true }),
});

module.exports = {
  createPurposeWalletSchema,
  updatePurposeWalletSchema,
  transferSchema,
};
