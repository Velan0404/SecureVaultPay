# SecureVault Pay Architecture

## Project Architecture Overview

SecureVault Pay follows a layered architecture designed for scalability, maintainability, and security.

The application is divided into four major layers:

- Flutter Mobile Application (Presentation Layer)
- Node.js Backend (Business Layer)
- Prisma ORM (Data Access Layer)
- PostgreSQL Database (Persistence Layer)

Firebase Cloud Messaging (FCM) is integrated only for push notifications.

---

# High-Level System Architecture

```
                        Flutter Mobile App
                               │
                               │
                     HTTPS REST API
                               │
                               ▼
                    Node.js (Express.js)
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                    │
          ▼                    ▼                    ▼
 Authentication Service   Wallet Service   Scheduler Service
          │                    │                    │
          └────────────────────┼────────────────────┘
                               │
                          Prisma ORM
                               │
                               ▼
                          PostgreSQL
                               │
                               ▼
                  Firebase Cloud Messaging
                  (Push Notifications Only)
```

---

# Authentication Architecture

## First-Time User

```
Splash Screen

↓

Register

↓

Create Password

↓

Create 6-digit App PIN

↓

Enable Fingerprint

↓

Load Demo Wallet

↓

Dashboard
```

---

## Returning User

```
Splash Screen

↓

Check Login Session

↓

Fingerprint Authentication

↓

Success
      │
      ▼
 Dashboard

Failure
      │
      ▼
 App PIN

Correct PIN
      │
      ▼
 Dashboard

Incorrect PIN
      │
      ▼
 Retry / Logout
```

---

# Wallet Architecture

The application contains one Main Wallet.

The Main Wallet acts as the primary wallet where all money is stored.

Users can create multiple Purpose Wallets.

Examples:

- Grocery
- Shopping
- Travel
- Utility
- Entertainment
- Savings
- Custom Wallet

Money Flow

```
Main Wallet

↓

Purpose Wallet

↓

Merchant Payment
```

---

# Scheduled Payment Architecture

Users can schedule future payments.

Examples:

- Rent
- Salary
- Scholarship
- Insurance
- Electricity Bill
- Internet Bill
- Subscription
- Family Transfer
- Gift
- Custom Payment

Execution Flow

```
User Creates Schedule

↓

PostgreSQL

↓

Node Cron Scheduler

↓

Execute Payment

↓

Update Transaction

↓

Send Push Notification (FCM)
```

---

# Notification Architecture

Firebase is NOT used as the application database.

Firebase is used only for push notifications.

Notification Types

- Payment Successful
- Payment Failed
- Scheduled Payment Reminder
- Wallet Transfer Successful
- Security Alerts

Flow

```
Node.js

↓

Firebase Admin SDK

↓

Firebase Cloud Messaging

↓

Flutter Mobile App
```

---

# Database Architecture

Database

PostgreSQL

ORM

Prisma

Tables

- Users
- MainWallet
- PurposeWallet
- WalletTransfer
- Transactions
- ScheduledPayments
- Merchants
- Notifications
- AuditLogs

Future Tables (Optional)

- DeviceSessions
- RefreshTokens
- AppSettings

---

# Backend Modules

Authentication Module

- Register
- Login
- JWT
- Password Encryption
- App PIN
- Fingerprint Verification Support

Wallet Module

- Main Wallet
- Purpose Wallet
- Wallet Transfer
- Balance Management

Payment Module

- Merchant Payment
- QR Payment (Demo)

Scheduler Module

- Scheduled Payments
- Node Cron Jobs

Notification Module

- Firebase Cloud Messaging

Analytics Module

- Dashboard
- Reports
- Spending Analysis

Profile Module

- User Profile
- Settings
- Security

---

# Flutter Modules

Authentication

- Splash Screen
- Login
- Register
- App PIN
- Fingerprint

Dashboard

Wallet

- Main Wallet
- Purpose Wallet

Payments

- Merchant Payment
- QR Payment

Scheduled Payments

Analytics

Notifications

Profile

Settings

Reusable Components

- Widgets
- Theme
- Routes
- Services
- Models
- Providers
- Utilities

---

# Coding Architecture

The application follows Clean Architecture.

```
Presentation Layer
        │
        ▼
Business Logic Layer
        │
        ▼
Service Layer
        │
        ▼
Repository Layer
        │
        ▼
Prisma ORM
        │
        ▼
PostgreSQL
```

---

# Security Architecture

Authentication

- JWT Authentication
- bcrypt Password Hashing
- App PIN Authentication
- Fingerprint Authentication

Storage

- Flutter Secure Storage
- Environment Variables
- Encrypted JWT Storage

Backend Security

- Helmet
- CORS
- Input Validation
- Rate Limiting (Future)
- Error Handling

Database Security

- Prisma ORM
- Parameterized Queries
- Database Transactions
- Decimal Currency Storage

---

# Development Principles

- Clean Architecture
- SOLID Principles
- Modular Development
- Reusable Components
- Scalable Design
- Secure by Default
- Separation of Concerns
- Production-Ready Code