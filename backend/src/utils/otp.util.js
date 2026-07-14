const crypto = require('crypto');

function generateOtp() {
  return crypto.randomInt(0, 1_000_000).toString().padStart(6, '0');
}

function hashOtp(otp) {
  return crypto.createHash('sha256').update(otp).digest('hex');
}

function verifyOtpHash(otp, hash) {
  return hashOtp(otp) === hash;
}

module.exports = { generateOtp, hashOtp, verifyOtpHash };
