# Transaction Authentication API

Base path: `/api/transaction-auth`. All routes require `Authorization: Bearer <accessToken>`.

This is the mandatory security layer in front of Main Wallet → Purpose Wallet
transfers: **fingerprint, then a Twilio Verify OTP, then the transfer**.
Nothing here modifies login, registration, JWT/refresh, or the Wallet module
itself — `POST /api/wallet/transfer` gained exactly one new required field
(`transactionAuthSessionId`) and one guard middleware ahead of its existing,
unmodified controller.

## PATCH /phone

`{ phoneNumber }` (international format). Sets the number Twilio sends OTPs
to. Collected automatically at registration since Phase 4.5 — this endpoint
exists for updating it afterward (Profile screen).

## POST /start

Rate limited: 10/day per user.

`{ deviceId, purposeWalletId, amount }` → `{ sessionId, expiresAt }`.
Verifies the Purpose Wallet is owned by this user and active, then creates a
`TransactionAuthSession` row (status `PENDING_FINGERPRINT`, 10-minute TTL).

## POST /:sessionId/confirm-fingerprint

Called after a **local, on-device** biometric success (`BiometricService`,
unchanged). Advances the session to `FINGERPRINT_CONFIRMED`. Idempotent per
session — calling it again once already confirmed returns
`INVALID_SESSION_STATE` rather than erroring destructively.

## POST /:sessionId/fingerprint-failed

Write-only telemetry — `{ attemptNumber }`. The 3-attempt retry limit itself
is enforced entirely client-side; this just records the event and, on the
3rd failure, marks the session `CANCELLED` server-side too.

## POST /:sessionId/otp/send

Rate limited: 3/hour per user. Requires `FINGERPRINT_CONFIRMED`. Calls Twilio
Verify to send the code to the account's `phoneNumber`, then sets `OTP_SENT`
+ `otpSentAt`. Fails with `PHONE_NUMBER_REQUIRED` if unset, or
`TWILIO_NOT_CONFIGURED` if the server has no Twilio credentials.

## POST /:sessionId/otp/verify

Rate limited: 20/hour per user (coarse backstop — the real 5-attempt cap is
tracked per-session). `{ code }`. Requires `OTP_SENT` and under 5 minutes
old, else `OTP_EXPIRED`. Verifies against Twilio (never generated or stored
locally). On success: `OTP_VERIFIED` + `otpVerifiedAt`.

## Using the session to transfer

`POST /api/wallet/transfer` now requires `transactionAuthSessionId` in the
body alongside the existing `purposeWalletId`/`amount`. The guard middleware
atomically "claims" the session (`OTP_VERIFIED` → `COMPLETED`) — this is
single-use and race-condition safe, so a session can authorize exactly one
transfer, and it must match the exact wallet + amount it was created for.
Every outcome (success or failure) writes an audit log and, on success,
sends a "Transfer Successful" push notification via Firebase.

## OTP rules (per project requirements)

- Twilio Verify owns OTP generation and validation entirely — no code is
  ever generated or stored by this backend.
- Expiry: 5 minutes (enforced by this backend against `otpSentAt`,
  independent of Twilio's own internal window).
- Max verification attempts: 5 per session, then a new OTP must be requested.
