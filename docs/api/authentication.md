# Authentication API

Base path: `/api/auth`. All request/response bodies are JSON.
Success responses: `{ "success": true, "data": {...} }`. Errors: `{ "success": false, "error": { "code", "message" } }`.

## POST /register

Creates a new account. Rate limited (10/hour per IP).

| Field | Type | Notes |
|---|---|---|
| `fullName` | string | required |
| `email` | string | required, unique |
| `phoneNumber` | string | **required as of Phase 4.5** — international format, e.g. `+919876543210`. Stored on the account and reused by Transaction Authentication for Twilio OTP delivery on Main Wallet transfers — no separate step needed after registration. |
| `password` | string | required, 8+ chars, letter + number |
| `device` | object | `{ deviceId, deviceName?, platform: "ANDROID"\|"IOS", fcmToken? }` |

Response: `{ user: { id, fullName, email, phoneNumber, biometricEnabled, createdAt }, accessToken, refreshToken }`

## POST /login

`{ email, password, device }` → same response shape as register. Rate limited (5/15min per email+IP, successful logins don't count).

## POST /refresh

`{ refreshToken }` → `{ accessToken, refreshToken }`. Rotates the refresh token; reuse of an already-rotated token revokes the whole token family.

## POST /logout / POST /logout-all

`{ refreshToken }` (logout) or none (logout-all, requires `Authorization: Bearer <accessToken>`).

## PIN

- `POST /pin/set` (auth) — `{ pin }` (6 digits).
- `POST /pin/verify` (auth, rate limited 5/15min, successes don't count) — `{ pin }`.
- `POST /pin/lockout-report` (auth) — `{ deviceId }`, called after 5 local PIN failures.

## Forgot / Reset Password

- `POST /forgot-password` (rate limited 3/hour) — `{ email }`. Always returns success to avoid email enumeration.
- `POST /reset-password` (rate limited 5/hour) — `{ email, otp, newPassword }`. This OTP is a separate, self-hosted 6-digit code (hashed, stored in `PasswordResetOtp`, delivered by email via Resend) — unrelated to the Twilio-based Transaction Authentication OTP.

## GET /check-session

Auth required. Returns the current `user` object — used on app resume to confirm the session is still valid server-side.

## PATCH /device/fcm-token

Auth required. `{ deviceId, fcmToken }` — keeps the push token current when Firebase rotates it.

---

## PIN persistence (device-local, not session-local)

The PIN hash/salt and biometric-enabled flag are stored in secure storage and are **device setup state**, not session state. Logging out clears only the access/refresh tokens — it does **not** delete the PIN, so a user who logs out and back in on the same device is never asked to create a PIN again. A PIN is only cleared by an explicit reset, a new device, or a reinstall (the latter two have nothing to clear in a fresh keystore anyway).
