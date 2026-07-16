const AppError = require('./appError');

const RANGE_PRESETS = ['TODAY', 'LAST_7_DAYS', 'LAST_30_DAYS', 'LAST_90_DAYS', 'THIS_YEAR', 'CUSTOM'];

// Plain Date mutation, same idiom scheduledPayment.service.js's
// getDashboardSummary() already uses — no new date library introduced for
// this. `end` is always exclusive (createdAt < end), `start` inclusive.
function resolveRange({ range, startDate, endDate }) {
  const now = new Date();
  const startOfToday = new Date(now);
  startOfToday.setHours(0, 0, 0, 0);
  const startOfTomorrow = new Date(startOfToday);
  startOfTomorrow.setDate(startOfTomorrow.getDate() + 1);

  if (!range || !RANGE_PRESETS.includes(range)) {
    throw new AppError(400, 'INVALID_RANGE', `range must be one of: ${RANGE_PRESETS.join(', ')}.`);
  }

  switch (range) {
    case 'TODAY':
      return { start: startOfToday, end: startOfTomorrow, preset: range };
    case 'LAST_7_DAYS': {
      const start = new Date(startOfTomorrow);
      start.setDate(start.getDate() - 7);
      return { start, end: startOfTomorrow, preset: range };
    }
    case 'LAST_30_DAYS': {
      const start = new Date(startOfTomorrow);
      start.setDate(start.getDate() - 30);
      return { start, end: startOfTomorrow, preset: range };
    }
    case 'LAST_90_DAYS': {
      const start = new Date(startOfTomorrow);
      start.setDate(start.getDate() - 90);
      return { start, end: startOfTomorrow, preset: range };
    }
    case 'THIS_YEAR': {
      const start = new Date(now.getFullYear(), 0, 1);
      return { start, end: startOfTomorrow, preset: range };
    }
    case 'CUSTOM': {
      if (!startDate || !endDate) {
        throw new AppError(400, 'INVALID_RANGE', 'startDate and endDate are required when range is CUSTOM.');
      }
      const start = new Date(startDate);
      const end = new Date(endDate);
      if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) {
        throw new AppError(400, 'INVALID_RANGE', 'startDate/endDate must be valid ISO date-times.');
      }
      if (start >= end) {
        throw new AppError(400, 'INVALID_RANGE', 'startDate must be before endDate.');
      }
      return { start, end, preset: range };
    }
    default:
      throw new AppError(400, 'INVALID_RANGE', `range must be one of: ${RANGE_PRESETS.join(', ')}.`);
  }
}

module.exports = { RANGE_PRESETS, resolveRange };
