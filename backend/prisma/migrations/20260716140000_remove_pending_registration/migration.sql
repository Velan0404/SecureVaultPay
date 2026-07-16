-- Phase 8.1.2 — Signup OTP Verification removed (dev-only revert). The
-- PendingRegistration table backed that flow exclusively; with the flow
-- gone, this table and its status enum are unused and dropped.
DROP TABLE "PendingRegistration";

DROP TYPE "PendingRegistrationStatus";
