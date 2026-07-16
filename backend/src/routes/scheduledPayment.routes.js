const express = require('express');
const scheduledPaymentController = require('../controllers/scheduledPayment.controller');
const authenticate = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate.middleware');
const requirePaymentPin = require('../middlewares/paymentPin.middleware');
const { scheduledPaymentCreateLimiter } = require('../middlewares/rateLimit.middleware');
const { createScheduledPaymentSchema, updateScheduledPaymentSchema } = require('../utils/scheduledPayment.validation');

const router = express.Router();

// Every Scheduled Payment endpoint is user-scoped and private, same as
// every other payment module.
router.use(authenticate);

// Static routes declared before /:id — the Phase 5.1.1 static-before-dynamic
// lesson this project re-checks every phase.
router.get('/dashboard', scheduledPaymentController.getDashboardSummary);
router.get('/', scheduledPaymentController.list);

// validate() runs first so `paymentPin` is confirmed well-formed before
// requirePaymentPin verifies it against the stored hash and strips it from
// req.body — same ordering as merchant/personal-payment routes. Create/Edit
// are the only two actions that require the Payment PIN; Pause/Resume/Cancel
// only ever reduce what will be charged, never redirect or increase it.
router.post(
  '/',
  scheduledPaymentCreateLimiter,
  validate(createScheduledPaymentSchema),
  requirePaymentPin,
  scheduledPaymentController.create,
);

router.get('/:id', scheduledPaymentController.getOne);
router.get('/:id/executions', scheduledPaymentController.listExecutions);

router.patch(
  '/:id',
  scheduledPaymentCreateLimiter,
  validate(updateScheduledPaymentSchema),
  requirePaymentPin,
  scheduledPaymentController.update,
);

router.post('/:id/pause', scheduledPaymentController.pause);
router.post('/:id/resume', scheduledPaymentController.resume);
router.delete('/:id', scheduledPaymentController.cancel);

module.exports = router;
