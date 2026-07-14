// Notification abstraction for security alerts.
// Firebase Admin integration is deferred to the Notification module — until
// the service account credentials are provided, alerts are logged instead of pushed.

async function sendSecurityAlert(userId, { title, body, data = {} } = {}) {
  console.log(`[NotificationService] (stub) security alert for user ${userId}: ${title} — ${body}`, data);
}

module.exports = { sendSecurityAlert };
