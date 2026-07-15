# SecureVault Pay Development Tasks

## Project Setup

- [x] Create Flutter Project
- [x] Create Node.js Backend
- [x] Configure PostgreSQL
- [x] Configure Prisma
- [x] Configure GitHub

---

## Authentication

- [x] Register (collects mobile number via a fixed +91 prefix + 10-digit input; always initializes fresh device setup, required for Transaction Authentication OTP delivery)
- [x] Login (a returning device still passes through fingerprint/PIN unlock after credentials verify — never skips straight to Dashboard, never re-asks Create PIN)
- [x] JWT (access + refresh, rotation with reuse detection)
- [x] Fingerprint Login
- [x] App PIN — device state, separate from account state: created once per device (register always creates a fresh one; login/returning sessions reuse it and never re-ask), persists across logout, cleared only by explicit reset/new device/reinstall
- [x] Session Restore / Splash session check
- [x] Logout
- [x] Forgot Password / Reset Password (OTP)
- [x] Secure Storage (flutter_secure_storage)
- [x] Firebase Cloud Messaging readiness (init, permission, token gen/refresh/upload, foreground/background/terminated handlers)
- [x] Backend security audit (rate limiting, hashing, CORS, Helmet, validation)
- [x] Phase 3.9 production-readiness audit — no critical issues found

---

## Dashboard

- [x] Home Screen
- [x] Quick Actions (Add Wallet, Transfer, History, Schedule, Pay Merchant)
- [x] Recent Transactions

---

## Wallet

- [x] Main Wallet (auto-provisioned lazily, one per user)
- [x] Load Demo Wallet (dev-only, one-time ₹100,000)
- [x] Purpose Wallets (create, edit, soft-delete/archive, view)
- [x] Create Wallet
- [x] Wallet Transfer (Main -> Purpose, atomic, race-condition safe, now requires Transaction Authentication)
- [x] Transaction History (paginated)
- [x] Phase 4 live device + backend E2E testing — no critical issues found
- [x] Premium dark UI redesign (design system, bottom nav shell, all wallet/dashboard screens)

---

## Security (Transaction Authentication)

- [x] Fingerprint confirmation (on-device, mandatory, max 3 attempts)
- [x] Twilio Verify OTP (generation/validation entirely on Twilio's side, 5-minute expiry, 5 attempts)
- [x] Session-gated Main Wallet -> Purpose Wallet transfers (single-use, race-condition safe) — scope narrowed back to Wallet Transfer only as of Phase 5.1 (Merchant Payment now uses the Payment PIN instead)
- [x] Real-money live test completed: real OTP sent + verified + transfer executed + replay rejected
- [x] Firebase push notification on successful transfer (real Admin SDK integration)
- [x] Audit logging (user, device, time, amount, wallet, transaction id) + analytics events

---

## Payment PIN

- [x] Dedicated 6-digit Payment PIN, separate from the App PIN (own `PaymentPin` table, bcrypt-hashed, never stored in plaintext)
- [x] Authorizes Merchant Payments only — never replaces login password, App PIN, or fingerprint
- [x] Created once, first payment only (Create -> Confirm -> stored -> payment completes in the same flow)
- [x] Verified server-side on every merchant payment (never a client-cached check)
- [x] Create/Confirm/Enter Payment PIN screens matching the App PIN's design

---

## Payments

- [ ] QR Payment
- [x] Merchant Payment (Main Wallet -> Purpose Wallet -> Merchant only, Main Wallet never selectable; 10 demo merchants seeded; authorized by Payment PIN, no fingerprint/OTP)
- [ ] Bill Payment

---

## Scheduled Payments

- [ ] Create Schedule
- [ ] Edit Schedule
- [ ] Cancel Schedule
- [ ] Scheduler

---

## Analytics

- [ ] Dashboard Charts
- [ ] Spending Reports

---

## Notifications

- [x] Payment Success (real Firebase push on successful transfer or merchant payment)
- [ ] Scheduled Payment Reminder

---

## Profile

- [x] User Profile (real name/email/biometric status/wallet count)
- [x] Transfer verification phone number
- [ ] Settings (notifications, privacy — coming-soon placeholders)

---

## Testing

- [ ] Authentication Testing
- [ ] Wallet Testing
- [ ] Scheduler Testing
- [ ] API Testing
- [ ] UI Testing

---

## Deployment

- [ ] Mobile Build
- [ ] Backend Deployment