const { z } = require('zod');

const passwordSchema = z
  .string()
  .min(8, 'Password must be at least 8 characters long.')
  .regex(/[A-Za-z]/, 'Password must contain at least one letter.')
  .regex(/[0-9]/, 'Password must contain at least one number.');

const pinSchema = z.string().regex(/^\d{6}$/, 'PIN must be exactly 6 digits.');

// International format, e.g. +919876543210 — same shape Transaction
// Authentication requires for Twilio Verify delivery.
const phoneNumberSchema = z
  .string()
  .regex(/^\+[1-9]\d{7,14}$/, 'Enter a mobile number in international format, e.g. +919876543210.');

const deviceSchema = z.object({
  deviceId: z.string().min(1, 'deviceId is required.'),
  deviceName: z.string().optional(),
  platform: z.enum(['ANDROID', 'IOS']),
  fcmToken: z.string().optional(),
});

const registerSchema = z.object({
  fullName: z.string().min(1, 'Full name is required.'),
  email: z.string().email('Enter a valid email address.'),
  phoneNumber: phoneNumberSchema,
  password: passwordSchema,
  device: deviceSchema,
});

const loginSchema = z.object({
  email: z.string().email('Enter a valid email address.'),
  password: z.string().min(1, 'Password is required.'),
  device: deviceSchema,
});

const refreshSchema = z.object({
  refreshToken: z.string().min(1, 'refreshToken is required.'),
});

const logoutSchema = z.object({
  refreshToken: z.string().min(1, 'refreshToken is required.'),
});

const pinSetSchema = z.object({
  pin: pinSchema,
});

const pinVerifySchema = z.object({
  pin: pinSchema,
});

const pinLockoutReportSchema = z.object({
  deviceId: z.string().min(1, 'deviceId is required.'),
});

const forgotPasswordSchema = z.object({
  email: z.string().email('Enter a valid email address.'),
});

const resetPasswordSchema = z.object({
  email: z.string().email('Enter a valid email address.'),
  otp: z.string().regex(/^\d{6}$/, 'OTP must be exactly 6 digits.'),
  newPassword: passwordSchema,
});

const fcmTokenUpdateSchema = z.object({
  deviceId: z.string().min(1, 'deviceId is required.'),
  fcmToken: z.string().min(1, 'fcmToken is required.'),
});

module.exports = {
  registerSchema,
  loginSchema,
  refreshSchema,
  logoutSchema,
  pinSetSchema,
  pinVerifySchema,
  pinLockoutReportSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  fcmTokenUpdateSchema,
  // Exported additively (Phase 7.1) so personalPayment.controller.js's phone
  // search can validate against the exact same international-format rule
  // registration already enforces, instead of duplicating the regex.
  phoneNumberSchema,
};
