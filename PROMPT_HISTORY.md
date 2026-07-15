# SecureVault Pay - Prompt History

This document records every prompt given to Claude Code during development.

Purpose:

- Keep development history.
- Prevent duplicate work.
- Help team members understand previous AI-generated code.
- Maintain consistency across multiple Claude Code sessions.
- Track architectural decisions.

---

# Project Information

Project Name

SecureVault Pay

Team Members

- Velan S
- Varshini

Frontend

Flutter

Backend

Node.js (Express)

Database

PostgreSQL

ORM

Prisma

Authentication

JWT

bcrypt

Fingerprint (local_auth)

Version Control

Git

GitHub

---

# Development Rules

Before every development session:

1. Read PROJECT_CONTEXT.md.
2. Read CLAUDE_RULES.md.
3. Read ARCHITECTURE.md.
4. Review TASKS.md.
5. Continue from the latest completed task.
6. Never modify unrelated files.
7. Follow existing architecture.
8. Explain major architectural changes before implementation.

---

# Prompt History

---

## Session 1

Date:

Developer:

Status:

Prompt:

Read PROJECT_CONTEXT.md, CLAUDE_RULES.md, ARCHITECTURE.md, and TASKS.md completely.

Analyze the project requirements.

Do not generate application code yet.

Understand the project architecture.

Review the technology stack.

Review the application workflow.

Review the coding standards.

Review the folder structure.

Suggest improvements if necessary.

Then generate only the complete project folder structure for Flutter, Node.js, and PostgreSQL.

Do not generate business logic.

Do not generate UI.

Do not generate database schema.

Wait for confirmation before moving to the next step.

Result:

(To be filled after Claude completes the task.)

---

## Session 2

Date:

2026-07-14

Developer:

Velan S

Status:

Completed

Prompt:

Phase 3.5 – Authentication Verification & Completion. Audit every authentication feature (Registration, Login, JWT Session Restore, Splash → Session Check, Fingerprint, PIN Fallback, Logout, Forgot/Reset Password, Secure Storage, Biometric Enrollment, PIN Lockout, Navigation Flow) plus Firebase/FCM readiness (init, permission, token generation/logging/upload, backend storage) without implementing notification sending.

Result:

Added POST_NOTIFICATIONS manifest permission, `PushNotificationService` (permission request + token debug logging + refresh listener), wired FCM token refresh into `AuthNotifier`. Fixed a PIN/biometric unlock bug where a network failure during session-check was conflated with an incorrect PIN (added `PinUnlockResult.networkError`). Fixed silent biometric-enrollment failures (no user feedback) by surfacing a snackbar. Broadened network-error handling across all auth screens. Verified all backend auth endpoints live via HTTP and confirmed FCM token persistence in PostgreSQL.

---

## Session 3

Date:

2026-07-14

Developer:

Velan S

Status:

Completed

Prompt:

Biometric Authentication Debug. Biometric login always fell back to PIN with a generic "Could not confirm biometric login" message. Trace the full flow (Enable Biometric screen → BiometricService → local_auth → Secure Storage → AuthProvider → Splash → PIN Unlock), verify each local_auth call, log exact return values/exceptions, verify `biometricEnabled` persistence, distinguish failure cases, and replace the generic message with the real root cause — without rewriting the authentication module or touching wallet/backend/UI theme/business logic.

Result:

Root cause found by reading the `local_auth_android` plugin source directly: `MainActivity.kt` extended `FlutterActivity` instead of `FlutterFragmentActivity`, which `local_auth` requires to host its `BiometricPrompt` fragment — every attempt failed with `LocalAuthExceptionCode.uiUnavailable` ("The current Activity must be a FragmentActivity"), silently swallowed by a bare `catch (_) { return false; }`. Fixed `MainActivity.kt` to extend `FlutterFragmentActivity`. Instrumented `BiometricService` with a `BiometricFailureReason` enum, debug logging of exact `local_auth` return values/exceptions, and a `failureMessage` getter; wired it into the Enable Biometric screen. Confirmed live on-device: `authenticate() -> true` with zero exceptions after the fix.

---

## Session 4

Date:

2026-07-14

Developer:

Velan S

Status:

Completed

Prompt:

Phase 3.9 – Final Authentication & Infrastructure Verification. Full production-readiness audit before starting Wallet development: authentication lifecycle, Firebase (including foreground/background/terminated notification handlers), backend (Express/Prisma/Neon/env vars/routes/middleware/logging/validation), security audit, Android platform config (icons, manifest, API 13/14 compatibility), `flutter analyze`, code quality (folder structure, SOLID, Riverpod, duplicate code, unused files/assets/dependencies), performance, git readiness, and live device testing. Fix only critical issues; do not start Wallet development.

Result:

No critical issues found anywhere. Added the missing FCM foreground (`onMessage`), background (`onBackgroundMessage`), and terminated-state (`getInitialMessage`) handlers to `push_notification_service.dart`/`main.dart` — previously only token generation/logging existed. `flutter analyze` clean (0 issues). Backend audit: no critical vulnerabilities; moderate/minor items deferred (missing `postinstall: prisma generate`, no `trust proxy` config, wide-open CORS, dead `JWT_REFRESH_SECRET` env var, sliding refresh expiry with no absolute cap). Android/performance audit: all PASS (custom launcher icon, matching native splash color, targetSdk 36, no memory leaks, no rebuild anti-patterns); one low-severity note (access token re-read from secure storage per request, not cached). Code quality/git audit: no secrets committed; one MEDIUM item (`google-services.json` tracked, not gitignored — deferred, policy decision); duplicated try/catch/snackbar boilerplate across 5 auth screens (refactor candidate, not fixed); 5 declared-but-unused dependencies (`qr_flutter`, `mobile_scanner`, `fl_chart`, `uuid`, `node-cron`) presumably staged for later phases. Live device retest confirmed session restore and biometric unlock (`authenticate() -> true`) working end-to-end after all fixes. Verdict: ready for Phase 4.

---

## Session 5

Date:

2026-07-14

Developer:

Velan S

Status:

Completed

Prompt:

Phase 4 – Wallet Module. Implement the complete Wallet System: Main Wallet (auto-provisioned, demo money, balance), Purpose Wallets (create/edit/delete/view with icon, color, purpose, spending limit), Wallet Transfers (Main -> Purpose, race-condition safe), Transaction History, and a Dashboard replacing the placeholder — following Repository -> Service -> Controller -> Routes on the backend and Provider/Model/Service/Repository on Flutter. No QR/merchant/scheduled payments/analytics/notifications/AI. Get schema approval before migrating; do not touch Authentication, Firebase config, or existing API architecture.

Result:

Schema approved (MainWallet, PurposeWallet, WalletTransfer, WalletTransaction with a future-proofed WalletTransactionType enum covering DEMO_LOAD/MAIN_TO_PURPOSE plus reserved PURPOSE_TO_MAIN/PURPOSE_PAYMENT/REFUND/ADJUSTMENT for later phases), migrated to Neon, Prisma client regenerated. Backend: `wallet.repository.js`/`wallet.service.js`/`wallet.controller.js`/`wallet.routes.js` mounted at `/api/wallet`, with atomic conditional `updateMany` transfers (compare-and-swap, no explicit row locking needed) inside `prisma.$transaction`, decimal amounts as strings end-to-end (never Float), soft-delete (archive) for Purpose Wallets to preserve the transaction audit trail. Live-tested every endpoint against Neon via PowerShell (auto-create, one-time demo money gate, create/transfer/insufficient-balance/dashboard-aggregation/transaction-history/delete-blocked-when-non-empty) — all passed. Flutter: models/service/repository/provider layers, 6 screens (Main Wallet, Create/Edit Wallet shared form, Wallet Details, Transfer Money, Transaction History) plus a real Dashboard, wired into the router and protected by the existing auth redirect logic with no changes needed there. `flutter analyze` clean. Live on-device testing (Xiaomi M2101K6I) found and fixed a real bug: `DropdownButtonFormField<PurposeWalletModel>` in the Transfer screen crashed after a dashboard refresh because Dart's default identity-based `==` no longer matched the previously-selected model instance against the freshly-parsed list — fixed by keying the dropdown on the wallet's `id` string instead of the model object. Device disconnected from ADB before the post-fix walkthrough could be re-verified live (a USB/connection issue, unrelated to the code) — `flutter analyze` stayed clean and the fix is straightforward, but a final on-device Transfer-screen confirmation is recommended once the device reconnects.

---

# Notes

Every new Claude Code session should append a new session entry instead of replacing previous entries.

Never delete prompt history.

This file acts as the development log for SecureVault Pay.