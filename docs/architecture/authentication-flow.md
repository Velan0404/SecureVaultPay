# Authentication Flow (Structure Reference)

This document maps the required login flow to the folders already reserved for it.
It contains no logic or UI — implementation happens in Phase 3 (Authentication module).

## Flow

```
Splash Screen
    ↓
Check Login Session
    ↓
Fingerprint Authentication
    ↓ (on failure)
App PIN
    ↓
Dashboard
```

## Planned file locations (to be created in Phase 3)

| Step                     | Location                                              |
|--------------------------|--------------------------------------------------------|
| Splash Screen            | `mobile/lib/screens/auth/`                              |
| Session check            | `mobile/lib/providers/` (auth session provider/notifier) |
| Fingerprint Authentication| `mobile/lib/screens/auth/` (uses `local_auth` package)  |
| App PIN                  | `mobile/lib/screens/auth/`                               |
| Secure token/session storage | `mobile/lib/services/` (uses `flutter_secure_storage`) |
| Route wiring             | `mobile/lib/routes/`                                     |
| Dashboard entry point    | `mobile/lib/screens/dashboard/`                          |

## Dependencies required (not yet installed)

- `local_auth` — fingerprint/biometric authentication
- `flutter_secure_storage` — secure storage of session token / PIN hash reference

These are deferred to the Authentication module phase per the project's dependency-minimalism rule.
