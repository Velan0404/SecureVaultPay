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
- Twilio Verify (Transaction Authentication OTP — Main Wallet transfers only, as of Phase 5.1)
- Payment PIN (bcrypt-hashed, separate from the App PIN — authorizes Merchant Payments)

Version Control

- Git
- GitHub

---

## Current Status

Phase 5.1 (Merchant Payment UX & Payment PIN) complete — Merchant Payments no longer require fingerprint or Twilio OTP; they're authorized by a dedicated 6-digit Payment PIN instead (bcrypt-hashed, its own `PaymentPin` table, completely separate from the App PIN). The first merchant payment prompts Create → Confirm Payment PIN; every payment after that only asks to enter it. The Dashboard's Quick Actions gained a fifth "Pay Merchant" shortcut (Select Purpose Wallet → Merchant List). Main Wallet → Purpose Wallet transfers are entirely unchanged and still require fingerprint + Twilio Verify OTP — that flow remains available for future high-risk operations. Money still only reaches a merchant via Main Wallet → Purpose Wallet → Merchant; Main Wallet is never a selectable payment source. 10 demo merchants are seeded across the 10 required categories; payments atomically debit the Purpose Wallet, write a `MerchantPayment` + `WalletTransaction` record, and appear automatically in Transaction History and the Dashboard's recent activity. The Security Upgrade Phase, the premium dark UI redesign, and the Wallet Module (Phase 4) are also complete. Authentication, backend infrastructure, and Firebase Cloud Messaging readiness were verified in Phase 3.9.

---

## Features

- Authentication
- Main Wallet
- Purpose Wallets
- Wallet Transfers
- QR Payment (Demo)
- Merchant Payment (Demo)
- Scheduled Payments
- Transaction History
- Analytics
- Notifications
- Profile

---

## Development Workflow

Read PROJECT_CONTEXT.md before making architectural decisions.