const scheduledPaymentService = require('../services/scheduledPayment.service');
const catchAsync = require('../utils/catchAsync');

const create = catchAsync(async (req, res) => {
  const schedule = await scheduledPaymentService.create(req.user.id, req.body);
  res.status(201).json({ success: true, data: { schedule } });
});

const list = catchAsync(async (req, res) => {
  const schedules = await scheduledPaymentService.list(req.user.id, { status: req.query.status });
  res.status(200).json({ success: true, data: { schedules } });
});

const getOne = catchAsync(async (req, res) => {
  const schedule = await scheduledPaymentService.getOne(req.user.id, req.params.id);
  res.status(200).json({ success: true, data: { schedule } });
});

const update = catchAsync(async (req, res) => {
  const schedule = await scheduledPaymentService.update(req.user.id, req.params.id, req.body);
  res.status(200).json({ success: true, data: { schedule } });
});

const pause = catchAsync(async (req, res) => {
  const schedule = await scheduledPaymentService.pause(req.user.id, req.params.id);
  res.status(200).json({ success: true, data: { schedule } });
});

const resume = catchAsync(async (req, res) => {
  const schedule = await scheduledPaymentService.resume(req.user.id, req.params.id);
  res.status(200).json({ success: true, data: { schedule } });
});

const cancel = catchAsync(async (req, res) => {
  const schedule = await scheduledPaymentService.cancel(req.user.id, req.params.id);
  res.status(200).json({ success: true, data: { schedule } });
});

const listExecutions = catchAsync(async (req, res) => {
  const result = await scheduledPaymentService.listExecutions(req.user.id, req.params.id, {
    cursor: req.query.cursor,
    limit: req.query.limit,
  });
  res.status(200).json({ success: true, data: result });
});

const getDashboardSummary = catchAsync(async (req, res) => {
  const summary = await scheduledPaymentService.getDashboardSummary(req.user.id);
  res.status(200).json({ success: true, data: summary });
});

module.exports = { create, list, getOne, update, pause, resume, cancel, listExecutions, getDashboardSummary };
