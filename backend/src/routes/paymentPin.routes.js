const express = require('express');
const paymentPinController = require('../controllers/paymentPin.controller');
const authenticate = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate.middleware');
const { paymentPinCreateLimiter } = require('../middlewares/rateLimit.middleware');
const { createPaymentPinSchema } = require('../utils/paymentPin.validation');

const router = express.Router();

router.use(authenticate);

router.get('/status', paymentPinController.status);
router.post('/', paymentPinCreateLimiter, validate(createPaymentPinSchema), paymentPinController.create);

module.exports = router;
