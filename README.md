# SecureVault Pay

## Team

- Velan S
- Varshini

---

## Project Overview

SecureVault Pay is a mobile-first fintech application focused on payment management rather than payment execution.

Unlike traditional payment apps, SecureVault Pay helps users organize money into purpose-based wallets while providing universal scheduled payments.

---

## Technology Stack

Frontend

- Flutter

Backend

- Node.js
- Express.js

Database

- PostgreSQL
- Prisma ORM

Authentication

- JWT
- bcrypt
- local_auth
- Twilio Verify (Transaction Authentication OTP — Main Wallet transfers only, as of Phase 5.1; the service itself is kept general-purpose and unmodified so it can support other flows later — Signup OTP Verification briefly reused it in Phase 8.1 and was removed again in Phase 8.1.2, a dev-only simplification)
- Payment PIN (bcrypt-hashed, separate from the App PIN — authorizes Merchant Payments, including via QR)

QR Payments

- mobile_scanner (camera-based QR scanning)
- qr_flutter (demo merchant QR rendering)

Analytics

- fl_chart (Monthly Spending line, Purpose Wallet pie, Weekly Expense bar, Income vs Expense charts)

Automation

- node-cron (Scheduled Payments execution engine — checks due payments every minute)

Version Control

- Git
- GitHub

---

## Current Status

Phase 8.1.2 (Remove Signup OTP) is complete — a development-only simplification. Signup OTP Verification (added in Phase 8.1, error-handling-improved in Phase 8.1.1) has been removed to make local testing easier: Registration now calls the original `POST /auth/register` endpoint directly again — Enter Details → Create Account (User + lazily-provisioned Main Wallet) → Create App PIN → Enable Biometric → Dashboard, exactly as it worked before Phase 8.1. The `PendingRegistration` table, its backend module (`signup.service/repository/controller/routes/validation.js`), its two rate limiters, and the Flutter Signup OTP screen/provider methods/API calls were all removed (the orphaned `PendingRegistration` table was dropped via a new migration). `auth.service.js`'s `register()`/`login()`, `auth.routes.js`, the Twilio service, Transaction Authentication, Payment PIN, and every other module were untouched — this was a pure removal of unused code, not a security change. The Analytics-cache-leak fix (`_resetPerAccountProviders()` in `auth_provider.dart`) and the Notifier `LateInitializationError` fix (both from Phase 8.1/8.1.1) remain in place, since both are still needed regardless of the signup flow. Twilio Verify OTP for Wallet Transfer (Transaction Authentication) is completely unaffected.

Phase 8.1.1 (Signup OTP + Riverpod Provider Crash fixes) preceded this — see PROMPT_HISTORY.md for the full root-cause writeups: the "Can't send verification code" signup error turned out to be a Twilio trial-account restriction (error 21608, sending only to verified numbers), not a code defect, fixed by making `twilio.service.js` surface real Twilio error codes/friendly messages outside production while staying fully generic in production; and a `LateInitializationError: _repository has already been initialized` crash, root-caused to Riverpod re-running `build()` on an existing (not fresh) Notifier instance when a still-listened provider is invalidated, fixed by converting every Notifier's `late final` repository field to a plain getter across the whole codebase.

Phase 8.1 (Analytics Dynamic Data Fix + Signup OTP Verification + UI Polish, since partially superseded — see above) fixed the real Analytics bug: Analytics was never leaking data on the backend — every query was already scoped by `req.user.id`. The bug was a Flutter-side provider lifecycle gap: the app's single, never-recreated root `ProviderScope` kept `analyticsProvider`/`walletProvider`/`scheduledPaymentProvider` (plain, non-`.autoDispose` `NotifierProvider`s) alive across logout/login, and each screen's "only load if not already loaded" guard then saw the previous account's cached state and skipped refetching — so a newly registered account could see the previous account's numbers. Fixed by invalidating all three providers on `logout()`/`register()`/`login()` in `auth_provider.dart`, which resets each provider to its real initial (empty) state so the very same guards now correctly detect "nothing loaded" and refetch for the new account. Genuinely empty accounts now see honest empty-state copy ("No transactions yet," "No spending data," "No wallet analytics") instead of any placeholder chart with fabricated numbers. The Analytics screens were also given a premium fintech redesign — a gradient hero balance card, shimmer loading skeletons, animated statistic count-ups, animated chart draw-in, animated progress bars, and real-data-only achievement badges — presentation only, no backend or model change. (This phase's Signup OTP Verification addition was removed again in Phase 8.1.2, above.)

Phase 8 (Analytics & Insights Module) complete — the Analytics tab is now real, built entirely on data that already existed: every payment/transfer module already writes to `WalletTransaction` (tagged by `type` and `purposeWalletId`), so grouping that one table by wallet and type answers almost every metric requested, with zero new database tables. Dashboard Analytics shows Total Balance, Total Income, Total Expenses, Total Transfers, Total Merchant Payments, Total User Payments, Total Scheduled Payments, and this month's spending, all filterable by Today / Last 7 Days / Last 30 Days / Last 90 Days / This Year / Custom Range. Purpose Wallet Analytics shows each wallet's current balance, total deposited, total spent, remaining budget, spending percentage, and transaction count from the same shared aggregate query — one query total, not one per wallet. Four `fl_chart` charts (Monthly Spending line, Purpose Wallet pie, Weekly Expense bar, Income vs Expense) share that same underlying data rather than re-querying it. Insights is a small rules engine — budget thresholds, spend-trend-vs-prior-period, dormant-wallet, and upcoming-scheduled-payment observations — generated only from real, already-computed figures, never fabricated. Reports (Daily/Weekly/Monthly) share the exact same totals-aggregation function the Dashboard uses, just resolved against a calendar period instead of an open filter. No Authentication, Wallet, Merchant Payment, QR Payment, Personal Payment, or Scheduled Payment file was modified — Analytics only reads through their already-public functions (`walletService.getDashboard()`, `scheduledPaymentService.getDashboardSummary()`).

Phase 7.1 (Personal Payment UX Improvements) is also complete — the Dashboard's "Pay Merchant" quick action was removed, since merchant payments already have a dedicated entry point (Scan QR → Merchant QR → Merchant Payment); Merchant Payment itself is untouched and still reachable exactly as before. In its place, a new "Pay" quick action starts a Person-to-Person payment by mobile number: enter a registered 10-digit number (the same fixed-`+91`-prefix UI Registration already uses) → Search → a new `GET /personal-payment/search` backend lookup → if found, the flow hands off to the *existing* Personal Payment Preview → Select Purpose Wallet → Confirm → Payment PIN → Success screens verbatim, with zero duplicated payment logic; if not found, an honest "No SecureVault Pay account found." message. The search response exposes only what's needed to identify a receiver (user id, display name, masked phone, SecureVault ID, profile image if any) — never a password, PIN, email, or wallet balance. My QR, Scan QR, Personal QR, and Merchant QR are all unchanged.

Phase 7 (Scheduled Payments & Automation) is also complete — users can now automate recurring Purpose Wallet payments (Rent, Electricity, Water, Internet, Mobile Recharge, Subscription, EMI, Insurance, Savings, Custom) to either a Merchant or another SecureVault Pay user, picked once at creation and fixed thereafter. Money still follows Main Wallet → Purpose Wallet → Merchant/User, never a shortcut. A `node-cron` job (`scheduler.service.js`) ticks every minute and executes due payments by calling the existing, unmodified `merchantService.pay()`/`personalPaymentService.pay()` directly — since those functions assume the Payment PIN was already verified by their caller and contain no PIN logic themselves, calling them straight from the scheduler (bypassing the HTTP/PIN layer entirely) means automatic execution never prompts for a PIN, while still getting full reuse of their balance-check, atomic-debit, transaction-record, and success-notification logic for free. The Payment PIN is required only when creating or editing a schedule — the same PIN screens used by every other payment module, now with a fourth branch. Each due cycle is claimed atomically (advance `nextExecution` before attempting payment, never after) so a schedule can never double-execute even if two ticks overlap; a failed cycle (e.g. insufficient balance) still advances to the next cycle rather than retrying every minute, and is logged to a per-schedule Execution History with a push notification. Schedules can be paused, resumed, or cancelled without a PIN, since those actions only ever reduce what will be charged. The Dashboard gained an independent "Scheduled Payments" block (Today / Upcoming 7-day total / Missed stats, plus the next few due schedules). No existing Merchant Payment, Merchant QR, or Personal QR file was modified — the scheduler only calls into their public `pay()` functions, exactly as a manual payment would.

Phase 7 (Personal QR / Receive Money) is also complete — every user now has a permanent Personal QR (`{type: 'USER_PAYMENT', userId, secureVaultId, version}`, no wallet balances or other sensitive data inside it) that other SecureVault Pay users can scan to send money straight into that user's Main Wallet. This is a distinct kind of QR from Merchant QR — Merchant QR is dynamic, single-use, and expires in 10 minutes; Personal QR is a permanent identity code, scanned repeatedly forever, never consumed. Money still follows Sender Main Wallet → Sender Purpose Wallet (selected) → Receiver Main Wallet, never directly from either Main Wallet; the debit-and-credit runs inside a single atomic database transaction (more atomic than Merchant QR's two-step compromise, since Personal Payment owns its own logic instead of delegating through an unmodified external service). Authorized by the exact same Payment PIN as Merchant/QR Payment — no biometric, no OTP. Both sender and receiver get a push notification and a `WalletTransaction` row, so Dashboard/Transaction History update for both people with no changes to either screen. The existing camera scanner (`QrScannerScreen`) now recognizes both Merchant QR and Personal QR payloads from one screen, and Profile gained a "My QR" button. Neither the Merchant Payment nor Merchant QR architecture from Phase 5/5.1/6 was modified.

Phase 6 (QR Merchant Payment Module) is also complete — a second entry point into the exact same Main Wallet → Purpose Wallet → Merchant payment engine: scanning a merchant's QR code instead of browsing the Merchant List. QR codes are dynamic, single-use, and expire after 10 minutes (a new `MerchantQrCode` table), which is what makes replay attacks, expired codes, and duplicate payments impossible — an atomic `ACTIVE → USED` compare-and-swap means the same QR can never fund two payments. Scanning never consumes a QR; only a completed payment does, and a failed payment (e.g. insufficient balance) releases it back to `ACTIVE` for retry. QR payment is authorized by the exact same Payment PIN as tap-to-pay — no biometric, no OTP — and reuses the untouched `merchantService.pay()` for the actual money movement, so Transaction History, Dashboard recent activity, and Merchant Spending update immediately with zero Wallet/Dashboard code changes. Since this project has no NPCI/UPI integration, a "Demo QR" screen on each Merchant's details page acts as the merchant terminal, rendering a real scannable QR image. Phase 5.1 (Merchant Payment UX & Payment PIN) is also complete — Merchant Payments are authorized by a dedicated 6-digit Payment PIN (bcrypt-hashed, its own `PaymentPin` table, completely separate from the App PIN); Main Wallet → Purpose Wallet transfers are entirely unchanged and still require fingerprint + Twilio Verify OTP. Main Wallet is never a selectable payment source anywhere in the app. The Security Upgrade Phase, the premium dark UI redesign, and the Wallet Module (Phase 4) are also complete. Authentication, backend infrastructure, and Firebase Cloud Messaging readiness were verified in Phase 3.9.

---

## Features

- Authentication
- Main Wallet
- Purpose Wallets
- Wallet Transfers
- QR Payment (Demo)
- Merchant Payment (Demo)
- Personal QR / Send to User
- Search & Pay by Mobile Number (Dashboard "Pay" — reuses the Personal Payment flow)
- Scheduled Payments (Rent, Electricity, Water, Internet, Mobile Recharge, Subscription, EMI, Insurance, Savings, Custom — automatic execution via node-cron)
- Transaction History
- Analytics
- Notifications
- Profile

---

## Development Workflow

Read PROJECT_CONTEXT.md before making architectural decisions.