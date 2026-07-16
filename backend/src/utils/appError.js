class AppError extends Error {
  constructor(statusCode, code, message, details) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    // Optional, non-production-only debug payload (see twilio.service.js)
    // — error.middleware.js only forwards this field when it's set.
    if (details !== undefined) this.details = details;
  }
}

module.exports = AppError;
