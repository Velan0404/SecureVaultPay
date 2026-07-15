const express = require('express');
const walletController = require('../controllers/wallet.controller');
const authenticate = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate.middleware');
const requireTransactionAuth = require('../middlewares/transactionAuth.middleware');
const { walletTransferLimiter, demoMoneyLimiter } = require('../middlewares/rateLimit.middleware');
const {
  createPurposeWalletSchema,
  updatePurposeWalletSchema,
  transferSchema,
} = require('../utils/wallet.validation');

const router = express.Router();

// Every wallet endpoint is user-scoped and private — no public routes here.
router.use(authenticate);

router.get('/main', walletController.getMainWallet);
router.post('/main/load-demo', demoMoneyLimiter, walletController.loadDemoMoney);

router.get('/purpose', walletController.listPurposeWallets);
router.post('/purpose', validate(createPurposeWalletSchema), walletController.createPurposeWallet);
router.get('/purpose/:id', walletController.getPurposeWallet);
router.patch('/purpose/:id', validate(updatePurposeWalletSchema), walletController.updatePurposeWallet);
router.delete('/purpose/:id', walletController.deletePurposeWallet);

// requireTransactionAuth runs BEFORE validate(transferSchema) deliberately —
// it needs the raw transactionAuthSessionId field, which transferSchema
// doesn't declare and would otherwise strip from req.body.
router.post(
  '/transfer',
  walletTransferLimiter,
  requireTransactionAuth,
  validate(transferSchema),
  walletController.transfer,
);

router.get('/transactions', walletController.listTransactions);
router.get('/dashboard', walletController.getDashboard);

module.exports = router;
