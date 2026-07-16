const cron = require('node-cron');
const repository = require('../repositories/scheduledPayment.repository');
const merchantService = require('./merchant.service');
const personalPaymentService = require('./personalPayment.service');
const notificationService = require('./notification.service');
const { addInterval } = require('../utils/scheduleInterval');

const REMINDER_WINDOW_HOURS = 24;

async function sendUpcomingReminders(now) {
  const in24h = new Date(now.getTime() + REMINDER_WINDOW_HOURS * 60 * 60 * 1000);
  const due = await repository.findDueForReminder(now, in24h);

  for (const schedule of due) {
    try {
      await notificationService.sendPushNotification(schedule.userId, {
        title: 'Upcoming Scheduled Payment',
        body: `"${schedule.title}" (₹${schedule.amount}) is due soon.`,
        data: { type: 'SCHEDULED_PAYMENT_REMINDER', scheduleId: schedule.id },
      });
    } catch (err) {
      console.error(`[Scheduler] Failed to send reminder for schedule ${schedule.id}:`, err.message);
    }
    await repository.markReminderSent(schedule.id, schedule.nextExecution);
  }
}

// Claim first, pay second — deliberate ordering. If the process crashes
// between the claim and the payment call, the worst case is one silently
// skipped cycle (safe: no money moved twice). Paying first and claiming
// after would risk a double-charge on the same crash, which is strictly
// worse for a payments system.
async function executeOne(schedule, now) {
  const dueAt = schedule.nextExecution;
  const computedNext = addInterval(dueAt, schedule.frequency, schedule.customIntervalDays);
  const willComplete = Boolean(schedule.endDate) && computedNext > schedule.endDate;
  const computedStatus = willComplete ? 'COMPLETED' : 'ACTIVE';

  const claimed = await repository.claimDueCycle(schedule.id, dueAt, {
    nextExecution: computedNext,
    status: computedStatus,
  });
  if (claimed.count === 0) return; // another tick already claimed this cycle

  let payment = null;
  let failureCode = null;
  try {
    if (schedule.merchantId) {
      payment = await merchantService.pay(
        schedule.userId,
        { merchantId: schedule.merchantId, purposeWalletId: schedule.purposeWalletId, amount: schedule.amount.toString() },
        null,
      );
    } else {
      payment = await personalPaymentService.pay(
        schedule.userId,
        {
          receiverId: schedule.receiverUserId,
          purposeWalletId: schedule.purposeWalletId,
          amount: schedule.amount.toString(),
          note: schedule.note,
        },
        null,
      );
    }
  } catch (err) {
    failureCode = err.code || 'UNKNOWN_ERROR';
  }

  await repository.createExecution({
    scheduledPaymentId: schedule.id,
    scheduledFor: dueAt,
    status: payment ? 'SUCCESS' : 'FAILED',
    amount: schedule.amount,
    failureReason: failureCode,
    paymentId: payment?.id ?? null,
  });

  // merchantService.pay()/personalPaymentService.pay() already send their
  // own "Payment Successful"/"Payment Sent"+"Payment Received" pushes on
  // success — nothing more to send here. On failure, the scheduler owns the
  // notification since it's schedule-specific, not a generic payment one.
  if (!payment) {
    try {
      await notificationService.sendPushNotification(schedule.userId, {
        title: failureCode === 'INSUFFICIENT_BALANCE' ? 'Insufficient Balance' : 'Scheduled Payment Failed',
        body: `"${schedule.title}" (₹${schedule.amount}) could not be completed.`,
        data: { type: 'SCHEDULED_PAYMENT_FAILED', scheduleId: schedule.id, reason: failureCode },
      });
    } catch (err) {
      console.error(`[Scheduler] Failed to send failure notification for schedule ${schedule.id}:`, err.message);
    }
  }

  if (willComplete) {
    try {
      await notificationService.sendPushNotification(schedule.userId, {
        title: 'Scheduled Payment Ended',
        body: `"${schedule.title}" has reached its end date and will no longer run.`,
        data: { type: 'SCHEDULED_PAYMENT_ENDED', scheduleId: schedule.id },
      });
    } catch (err) {
      console.error(`[Scheduler] Failed to send end-of-schedule notification for ${schedule.id}:`, err.message);
    }
  }
}

// Sequential, not Promise.all — bounded batch size (100/tick) is small
// enough that sequential execution keeps this simple and avoids bursting
// the DB connection pool, acceptable for this MVP's scale.
async function runDueExecutions(now) {
  const due = await repository.findDueForExecution(now);
  for (const schedule of due) {
    try {
      await executeOne(schedule, now);
    } catch (err) {
      console.error(`[Scheduler] Unexpected error executing schedule ${schedule.id}:`, err.message);
    }
  }
}

async function tick() {
  const now = new Date();
  await sendUpcomingReminders(now);
  await runDueExecutions(now);
}

let task = null;

// Started once from index.js after app.listen(...) — never from app.js, so
// the project's existing module-load verification technique
// (`node -e "require('./src/app.js')"`) never triggers a real cron loop.
function start() {
  if (task) return;
  task = cron.schedule('* * * * *', () => {
    tick().catch((err) => console.error('[Scheduler] Tick failed:', err.message));
  });
  console.log('[Scheduler] Started — checking due scheduled payments every minute.');
}

module.exports = { start, tick, runDueExecutions, sendUpcomingReminders };
