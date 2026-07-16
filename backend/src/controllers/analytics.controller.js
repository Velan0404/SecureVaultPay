const analyticsService = require('../services/analytics.service');
const catchAsync = require('../utils/catchAsync');

// Every action is a plain GET, scoped to req.user.id, reading req.query for
// its range/period — range/period validation happens inside
// analytics.service.js (resolveRange/resolvePeriod), same "validate inline,
// no req.body involved" precedent as merchant.controller.js's `category` and
// personalPayment.controller.js's `phone` query params.

const getDashboard = catchAsync(async (req, res) => {
  const dashboard = await analyticsService.getDashboardAnalytics(req.user.id, req.query);
  res.status(200).json({ success: true, data: dashboard });
});

const getWallets = catchAsync(async (req, res) => {
  const wallets = await analyticsService.getWalletAnalytics(req.user.id, req.query);
  res.status(200).json({ success: true, data: wallets });
});

const getCharts = catchAsync(async (req, res) => {
  const charts = await analyticsService.getCharts(req.user.id, req.query);
  res.status(200).json({ success: true, data: charts });
});

const getInsights = catchAsync(async (req, res) => {
  const insights = await analyticsService.getInsights(req.user.id, req.query);
  res.status(200).json({ success: true, data: insights });
});

const getReport = catchAsync(async (req, res) => {
  const report = await analyticsService.getReport(req.user.id, { period: req.query.period, date: req.query.date });
  res.status(200).json({ success: true, data: report });
});

module.exports = { getDashboard, getWallets, getCharts, getInsights, getReport };
