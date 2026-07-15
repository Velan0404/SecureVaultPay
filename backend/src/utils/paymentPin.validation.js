const { z } = require('zod');

// Same shape as the App PIN's pinSchema (auth.validation.js) — kept as its
// own copy rather than a shared import since Payment PIN is a deliberately
// separate credential from the App PIN, not a re-skin of it.
const paymentPinSchema = z.string().regex(/^\d{6}$/, 'PIN must be exactly 6 digits.');

const createPaymentPinSchema = z.object({
  pin: paymentPinSchema,
});

module.exports = { paymentPinSchema, createPaymentPinSchema };
