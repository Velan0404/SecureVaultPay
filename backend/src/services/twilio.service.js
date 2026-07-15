const AppError = require('../utils/appError');

// Lazily constructed — reading env vars and constructing the Twilio client
// at module-load time would crash the whole server on boot if Twilio isn't
// configured yet. Transaction Authentication is meant to fail loudly and
// specifically at the point of use instead, not take down the app.
let client = null;

function getClient() {
  const { TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_VERIFY_SERVICE_SID } = process.env;

  if (!TWILIO_ACCOUNT_SID || !TWILIO_AUTH_TOKEN || !TWILIO_VERIFY_SERVICE_SID) {
    throw new AppError(
      503,
      'TWILIO_NOT_CONFIGURED',
      'SMS verification is not configured on this server. Set TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and TWILIO_VERIFY_SERVICE_SID.',
    );
  }

  if (!client) {
    // eslint-disable-next-line global-require
    const twilio = require('twilio');
    client = twilio(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN);
  }
  return client;
}

// Twilio Verify generates and stores the OTP entirely on Twilio's side — this
// service never sees, generates, or persists the code itself.
async function sendOtp(phoneNumber) {
  const twilioClient = getClient();
  try {
    await twilioClient.verify.v2
      .services(process.env.TWILIO_VERIFY_SERVICE_SID)
      .verifications.create({ to: phoneNumber, channel: 'sms' });
  } catch (err) {
    throw new AppError(502, 'OTP_SEND_FAILED', 'Could not send the verification code. Please try again.');
  }
}

async function checkOtp(phoneNumber, code) {
  const twilioClient = getClient();
  try {
    const result = await twilioClient.verify.v2
      .services(process.env.TWILIO_VERIFY_SERVICE_SID)
      .verificationChecks.create({ to: phoneNumber, code });
    return result.status === 'approved';
  } catch (err) {
    // Twilio throws on a not-found/expired verification (e.g. after its own
    // internal TTL) rather than returning a "pending" status — treat that the
    // same as an invalid code instead of surfacing a 502 to the user.
    return false;
  }
}

module.exports = { sendOtp, checkOtp };
