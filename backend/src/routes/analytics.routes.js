const express = require('express');
const analyticsController = require('../controllers/analytics.controller');
const authenticate = require('../middlewares/auth.middleware');
const { analyticsLimiter } = require('../middlewares/rateLimit.middleware');

const router = express.Router();

// Every Analytics endpoint is user-scoped, private, and read-only, same as
// Wallet/Merchant/QR/Personal/Scheduled. All five are static single-segment
// paths — no dynamic :id route on this router, so no ordering risk.
router.use(authenticate);
router.use(analyticsLimiter);

router.get('/dashboard', analyticsController.getDashboard);
router.get('/wallets', analyticsController.getWallets);
router.get('/charts', analyticsController.getCharts);
router.get('/insights', analyticsController.getInsights);
router.get('/reports', analyticsController.getReport);

module.exports = router;
