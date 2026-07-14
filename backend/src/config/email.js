const { Resend } = require('resend');

let client = null;

function getResendClient() {
  if (!process.env.RESEND_API_KEY) {
    return null;
  }
  if (!client) {
    client = new Resend(process.env.RESEND_API_KEY);
  }
  return client;
}

module.exports = { getResendClient };
