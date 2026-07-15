# SecureVault Pay Development Tasks

## Project Setup

- [x] Create Flutter Project
- [x] Create Node.js Backend
- [x] Configure PostgreSQL
- [x] Configure Prisma
- [x] Configure GitHub

---

## Authentication

- [x] Register
- [x] Login
- [x] JWT (access + refresh, rotation with reuse detection)
- [x] Fingerprint Login
- [x] App PIN (create, verify, lockout)
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
- [x] Quick Actions
- [x] Recent Transactions

---

## Wallet

- [x] Main Wallet (auto-provisioned lazily, one per user)
- [x] Load Demo Wallet (dev-only, one-time ₹100,000)
- [x] Purpose Wallets (create, edit, soft-delete/archive, view)
- [x] Create Wallet
- [x] Wallet Transfer (Main -> Purpose, atomic, race-condition safe)
- [x] Transaction History (paginated)
- [x] Phase 4 live device + backend E2E testing — no critical issues found

---

## Payments

- [ ] QR Payment
- [ ] Merchant Payment
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

- [ ] Payment Success
- [ ] Scheduled Payment Reminder

---

## Profile

- [ ] User Profile
- [ ] Settings
- [ ] Security

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