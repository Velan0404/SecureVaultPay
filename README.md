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
- Twilio Verify (Transaction Authentication OTP for Main Wallet transfers)

Version Control

- Git
- GitHub

---

## Current Status

Security Upgrade Phase complete — Main Wallet transfers now require Transaction Authentication (mandatory fingerprint, then a Twilio Verify OTP) before executing, with real-money live testing completed (real SMS sent, verified, transfer executed, replay rejected). The premium dark UI redesign (design system, floating bottom navigation, all screens) and the Wallet Module (Phase 4) are also complete. Authentication, backend infrastructure, and Firebase Cloud Messaging readiness were verified in Phase 3.9. Awaiting confirmation before Phase 5.

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