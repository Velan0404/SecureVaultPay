# SecureVault Pay

## Project Overview

SecureVault Pay is a mobile-first fintech application built using Flutter.

The objective is NOT to replace Google Pay or PhonePe.

Existing payment applications mainly focus on payment execution.

SecureVault Pay focuses on payment organization, security, and payment automation.

The application allows users to organize money into multiple purpose-based wallets while providing a universal scheduled payment platform.

---

# Team

Velan S

Varshini

---

# Technology Stack

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

local_auth (Fingerprint)

flutter_secure_storage

Version Control

Git

GitHub

IDE

Claude Code

VS Code

---

# Design Reference

The complete UI is designed using Figma Make.

Claude must follow the Figma design.

Do not redesign the application unless required for usability.

Theme

Primary Background

#0D0D0D

Primary Color

#E53935

Typography

Poppins

Material 3

Premium fintech UI.

Inspired by

Google Wallet

Revolut

Monzo

Airtel Thanks

---

# Main Goal

Create a production-quality MVP.

The application should be modular, scalable and maintainable.

Do NOT generate beginner code.

Follow industry best practices.

---

# Core Idea

SecureVault Pay contains one Main Wallet.

The Main Wallet stores the user's money.

Users can create unlimited Purpose Wallets.

Examples

Grocery

Shopping

Travel

Entertainment

Savings

Utility

Custom

Money flows

Main Wallet

↓

Purpose Wallet

↓

Merchant

---

# Demo Mode

This MVP is NOT connected to a real bank.

After registration

Show

Load Demo Wallet

When clicked

Add ₹100000

into Main Wallet.

Purpose

Allow demonstration of wallet management without real banking APIs.

---

# Universal Scheduled Payments

Users can schedule

Rent

Salary

Scholarship

Gift

Insurance

Electricity

Internet

Subscriptions

Refund

Family Transfer

Custom Payment

The system automatically executes scheduled payments.

---

# Main Features

Authentication

Register

Login

Fingerprint Login

PIN Login

Dashboard

Main Wallet

Purpose Wallet

Wallet Transfer

Merchant Payment (Demo)

QR Payment (Demo)

Transaction History

Scheduled Payments

Notifications

Analytics

Profile

Settings

---

# Application Flow

Splash

↓

Login / Register

↓

Create PIN

↓

Enable Fingerprint

↓

Load Demo Wallet

↓

Dashboard

↓

Main Wallet

↓

Purpose Wallet

↓

Transfer Money

↓

Merchant Payment

↓

Scheduled Payments

↓

Analytics

↓

Transaction History

↓

Notifications

↓

Profile

---

# Folder Structure

mobile/

backend/

docs/

assets/

---

# Flutter Structure

lib/

core/

models/

services/

providers/

widgets/

screens/

routes/

theme/

utils/

---

# Backend Structure

src/

controllers/

routes/

middlewares/

services/

config/

prisma/

utils/

---

# Database Tables

Users

MainWallet

PurposeWallet

WalletTransfer

Transactions

ScheduledPayments

Notifications

AuditLogs

---

## Push Notifications

The application uses Firebase Cloud Messaging (FCM) only for push notifications.

Firebase is NOT used as the primary database.

All business data remains in PostgreSQL.

Firebase is responsible only for:

- Scheduled Payment Reminder
- Payment Success
- Payment Failure
- Wallet Transfer Notification
- Security Alerts
---

# Coding Standards

Follow SOLID Principles.

Create reusable widgets.

No duplicated code.

No hardcoded values.

Separate UI from business logic.

Separate business logic from database.

Use environment variables.

Write production-quality code.

Use meaningful file names.

Follow clean architecture.

Keep every module independent.

Every screen should be responsive.

Every API should have validation.

Every API should have proper error handling.

Use comments only where necessary.

---

# Development Rules

Never generate the complete project in one step.

Always build one module at a time.

Before creating new files

Check the project structure.

Never modify unrelated files.

If unsure

Ask before changing architecture.

Explain every important architectural decision.

Act as a Senior Flutter Engineer,
Senior Node.js Engineer,
Senior PostgreSQL Database Architect,
and Senior FinTech System Architect.

Always prioritize code quality over speed.