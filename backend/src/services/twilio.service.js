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

// Common Twilio Verify error codes worth surfacing as a friendly message
// instead of Twilio's raw wording — used only outside production (see
// sendOtp below). Reference: https://www.twilio.com/docs/api/errors
const TWILIO_FRIENDLY_ERRORS = {
  21608: 'This Twilio Trial account can only send OTP to verified phone numbers.',
  21211: 'The phone number is not a valid mobile number.',
  60203: 'Too many verification attempts for this number. Please wait before retrying.',
};

// Twilio Verify generates and stores the OTP entirely on Twilio's side — this
// service never sees, generates, or persists the code itself.
async function sendOtp(phoneNumber) {
  const twilioClient = getClient();
  try {
    await twilioClient.verify.v2
      .services(process.env.TWILIO_VERIFY_SERVICE_SID)
      .verifications.create({ to: phoneNumber, channel: 'sms' });
  } catch (err) {
    // Production never leaks Twilio internals to the client — same generic
    // message regardless of cause. Outside production, surface the real
    // Twilio error code/message so it's actually debuggable, using a
    // friendly wording for the common cases above and falling back to
    // Twilio's own message otherwise.
    if (process.env.NODE_ENV === 'production') {
      throw new AppError(502, 'OTP_SEND_FAILED', 'Unable to send verification code.');
    }
    const friendlyMessage = TWILIO_FRIENDLY_ERRORS[err.code] || err.message || 'Unable to send verification code.';
    throw new AppError(502, 'OTP_SEND_FAILED', friendlyMessage, {
      twilioCode: err.code,
      twilioMessage: err.message,
    });
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
