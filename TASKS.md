# SecureVault Pay Development Tasks

## Project Setup

- [x] Create Flutter Project
- [x] Create Node.js Backend
- [x] Configure PostgreSQL
- [x] Configure Prisma
- [x] Configure GitHub

---

## Authentication

- [x] Register (collects mobile number via a fixed +91 prefix + 10-digit input; always initializes fresh device setup, required for Transaction Authentication OTP delivery; calls the account-creation endpoint directly — Signup OTP Verification was added in Phase 8.1 and removed again in Phase 8.1.2 as a development-only simplification, see PROMPT_HISTORY.md)
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
- [x] Quick Actions (Add Wallet, Transfer, History, Schedule, Pay, Scan QR) — "Pay Merchant" removed as of Phase 7.1 (redundant with Scan QR -> Merchant QR -> Merchant Payment); replaced with "Pay" (Person -> Person, by mobile number search)
- [x] Recent Transactions
- [x] Scheduled Payments summary (Today / Upcoming 7d total / Missed stats + next few schedules)

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

- [x] QR Payment (dynamic, single-use, 10-minute-expiry demo QR per merchant; same Main Wallet -> Purpose Wallet -> Merchant flow and Payment PIN as tap-to-pay, no biometric/OTP; replay/duplicate prevented by an atomic ACTIVE->USED compare-and-swap)
- [x] Merchant Payment (Main Wallet -> Purpose Wallet -> Merchant only, Main Wallet never selectable; 10 demo merchants seeded; authorized by Payment PIN, no fingerprint/OTP)
- [x] Personal QR / Send to User (permanent per-user QR identifying a SecureVault Pay account; Main Wallet -> Purpose Wallet -> Receiver's Main Wallet, authorized by the same Payment PIN, no biometric/OTP; both sender and receiver get a push notification and a Wallet Transaction row)
- [x] Search User by Mobile Number (Dashboard "Pay" -> enter a 10-digit number, auto-formatted to +91XXXXXXXXXX same as Registration -> backend lookup -> found user reuses the exact existing Personal Payment Preview/Select Wallet/Confirm/Payment PIN flow; "No SecureVault Pay account found." when there's no match)
- [ ] Bill Payment

---

## Scheduled Payments

- [x] Create Schedule (Rent, Electricity, Water, Internet, Mobile Recharge, Subscription, EMI, Insurance, Savings, Custom; destination is a Merchant or another SecureVault Pay user, picked once and fixed thereafter; Payment PIN required)
- [x] Edit Schedule (amount, frequency, end date, title, note, Purpose Wallet — destination and category are fixed; Payment PIN required)
- [x] Pause / Resume Schedule (no Payment PIN — only ever reduces what will be charged)
- [x] Cancel Schedule (soft, no Payment PIN)
- [x] Scheduler (node-cron, every minute; automatically executes due payments by calling the existing, unmodified `merchantService.pay()`/`personalPaymentService.pay()` directly — no Payment PIN at execution time; atomic claim-before-pay prevents double-execution; insufficient-balance/inactive-destination failures are logged and notified, then the schedule advances to its next cycle rather than retrying every tick)
- [x] Execution History (per-schedule log of every cron-tick attempt: success/failure, amount, reason)

---

## Analytics

- [x] Dashboard Analytics (Total Balance, Total Income, Total Expenses, Total Transfers, Total Merchant Payments, Total User Payments, Total Scheduled Payments, Monthly Spending — all real, aggregated from existing `WalletTransaction`/`ScheduledPaymentExecution` data, zero new tables)
- [x] Purpose Wallet Analytics (per wallet: current balance, total deposited, total spent, remaining budget, spending percentage, transaction count)
- [x] Dashboard Charts (Monthly Spending line, Purpose Wallet Pie, Weekly Expense bar, Income vs Expense — `fl_chart`)
- [x] Insights (budget-threshold, spend-trend-vs-prior-period, dormant-wallet, and upcoming-scheduled-payment observations, all rule-generated from real data — never fabricated)
- [x] Filters (Today / Last 7 Days / Last 30 Days / Last 90 Days / This Year / Custom Range — shared across every Analytics screen, auto-refreshes on change)
- [x] Spending Reports (Daily / Weekly / Monthly summaries: income, expenses, transfers, merchant/personal/scheduled payments)
- [x] Per-account isolation (Phase 8.1) — `analyticsProvider`/`walletProvider`/`scheduledPaymentProvider` are invalidated on logout and login so a new account never reuses the previous account's cached state; genuine zero-data accounts see honest empty-state copy, never a fake chart
- [x] Premium UI polish (Phase 8.1) — gradient hero balance card, shimmer loading skeletons, animated stat count-ups, animated chart draw-in, animated progress bars, real-data-only achievement badges — presentation only, same backend/models

---

## Notifications

- [x] Payment Success (real Firebase push on successful transfer, merchant payment, or Personal Payment — sender and receiver each get their own message)
- [x] Scheduled Payment Reminder (24h-ahead "upcoming payment" push, deduped per due cycle)
- [x] Scheduled Payment Failed / Insufficient Balance / Ended (automatic-execution outcomes, pushed by the scheduler itself)

---

## Profile

- [x] User Profile (real name/email/biometric status/wallet count)
- [x] My QR (permanent Personal QR — name, mobile number, SecureVault ID; Share QR UI-only for now)
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