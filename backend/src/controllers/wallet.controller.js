const walletService = require('../services/wallet.service');
const catchAsync = require('../utils/catchAsync');

const getMainWallet = catchAsync(async (req, res) => {
  const wallet = await walletService.getMainWallet(req.user.id);
  res.status(200).json({ success: true, data: { wallet } });
});

const loadDemoMoney = catchAsync(async (req, res) => {
  const wallet = await walletService.loadDemoMoney(req.user.id);
  res.status(200).json({ success: true, data: { wallet } });
});

const listPurposeWallets = catchAsync(async (req, res) => {
  const wallets = await walletService.listPurposeWallets(req.user.id);
  res.status(200).json({ success: true, data: { wallets } });
});

const getPurposeWallet = catchAsync(async (req, res) => {
  const wallet = await walletService.getPurposeWallet(req.user.id, req.params.id);
  res.status(200).json({ success: true, data: { wallet } });
});

const createPurposeWallet = catchAsync(async (req, res) => {
  const wallet = await walletService.createPurposeWallet(req.user.id, req.body);
  res.status(201).json({ success: true, data: { wallet } });
});

const updatePurposeWallet = catchAsync(async (req, res) => {
  const wallet = await walletService.updatePurposeWallet(req.user.id, req.params.id, req.body);
  res.status(200).json({ success: true, data: { wallet } });
});

const deletePurposeWallet = catchAsync(async (req, res) => {
  await walletService.deletePurposeWallet(req.user.id, req.params.id);
  res.status(200).json({ success: true, data: { message: 'Wallet deleted successfully.' } });
});

const transfer = catchAsync(async (req, res) => {
  const result = await walletService.transfer(req.user.id, req.body);
  res.status(200).json({ success: true, data: { transfer: result } });
});

const listTransactions = catchAsync(async (req, res) => {
  const result = await walletService.listTransactions(req.user.id, {
    purposeWalletId: req.query.purposeWalletId,
    cursor: req.query.cursor,
    limit: req.query.limit,
  });
  res.status(200).json({ success: true, data: result });
});

const getDashboard = catchAsync(async (req, res) => {
  const dashboard = await walletService.getDashboard(req.user.id);
  res.status(200).json({ success: true, data: dashboard });
});

module.exports = {
  getMainWallet,
  loadDemoMoney,
  listPurposeWallets,
  getPurposeWallet,
  createPurposeWallet,
  updatePurposeWallet,
  deletePurposeWallet,
  transfer,
  listTransactions,
  getDashboard,
};
