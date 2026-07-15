const deviceService = require('./device.service');

// Lazily initialized so a missing/invalid service account doesn't crash the
// server on boot — pushes are best-effort and must never block the request
// that triggered them (a failed push shouldn't fail a successful transfer).
let messaging = null;
let initAttempted = false;

function getMessaging() {
  if (initAttempted) return messaging;
  initAttempted = true;

  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw) return null;

  try {
    // eslint-disable-next-line global-require
    const admin = require('firebase-admin');
    const serviceAccount = JSON.parse(raw);
    if (!admin.apps.length) {
      admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    }
    messaging = admin.messaging();
  } catch (err) {
    console.error('[NotificationService] Failed to initialize Firebase Admin:', err.message);
    messaging = null;
  }

  return messaging;
}

async function sendToUserDevices(userId, { title, body, data = {} }) {
  const fcm = getMessaging();
  if (!fcm) {
    console.log(`[NotificationService] (not configured) push for user ${userId}: ${title} — ${body}`, data);
    return;
  }

  const devices = await deviceService.listUserDevices(userId);
  const tokens = devices.map((d) => d.fcmToken).filter(Boolean);
  if (tokens.length === 0) return;

  try {
    await fcm.sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([key, value]) => [key, String(value)])),
    });
  } catch (err) {
    console.error(`[NotificationService] Push send failed for user ${userId}:`, err.message);
  }
}

async function sendSecurityAlert(userId, { title, body, data = {} } = {}) {
  await sendToUserDevices(userId, { title, body, data });
}

async function sendPushNotification(userId, { title, body, data = {} } = {}) {
  await sendToUserDevices(userId, { title, body, data });
}

module.exports = { sendSecurityAlert, sendPushNotification };
