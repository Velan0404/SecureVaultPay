// Pure date math shared by scheduledPayment.service.js (computing the very
// first nextExecution) and scheduler.service.js (advancing it after each
// run) — kept in one place so the two never drift apart.
function addInterval(date, frequency, customIntervalDays) {
  const next = new Date(date);
  switch (frequency) {
    case 'DAILY':
      next.setUTCDate(next.getUTCDate() + 1);
      break;
    case 'WEEKLY':
      next.setUTCDate(next.getUTCDate() + 7);
      break;
    case 'MONTHLY':
      next.setUTCMonth(next.getUTCMonth() + 1);
      break;
    case 'YEARLY':
      next.setUTCFullYear(next.getUTCFullYear() + 1);
      break;
    case 'CUSTOM':
      next.setUTCDate(next.getUTCDate() + customIntervalDays);
      break;
    default:
      throw new Error(`Unknown frequency: ${frequency}`);
  }
  return next;
}

module.exports = { addInterval };
