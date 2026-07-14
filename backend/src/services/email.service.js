const { getResendClient } = require('../config/email');

async function sendOtpEmail(toEmail, otp) {
  const client = getResendClient();

  if (!client) {
    if (process.env.NODE_ENV === 'production') {
      console.error(`[EmailService] RESEND_API_KEY not set — OTP email to ${toEmail} was not sent.`);
    } else {
      console.warn(`[EmailService] RESEND_API_KEY not set — dev fallback, OTP for ${toEmail} is ${otp}.`);
    }
    return;
  }

  const expiryMinutes = process.env.OTP_EXPIRY_MINUTES || 10;

  await client.emails.send({
    from: process.env.RESEND_FROM_EMAIL,
    to: toEmail,
    subject: 'SecureVault Pay — Password Reset Code',
    html: `<p>Your SecureVault Pay password reset code is:</p><h2>${otp}</h2><p>This code expires in ${expiryMinutes} minutes. If you did not request this, you can ignore this email.</p>`,
  });
}

module.exports = { sendOtpEmail };
