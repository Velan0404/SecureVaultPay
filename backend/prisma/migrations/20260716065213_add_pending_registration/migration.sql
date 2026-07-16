-- CreateEnum
CREATE TYPE "PendingRegistrationStatus" AS ENUM ('OTP_SENT', 'VERIFIED');

-- CreateTable
CREATE TABLE "PendingRegistration" (
    "id" TEXT NOT NULL,
    "fullName" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "phoneNumber" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "deviceId" TEXT NOT NULL,
    "deviceName" TEXT,
    "platform" "Platform" NOT NULL,
    "fcmToken" TEXT,
    "otpAttempts" INTEGER NOT NULL DEFAULT 0,
    "status" "PendingRegistrationStatus" NOT NULL DEFAULT 'OTP_SENT',
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PendingRegistration_pkey" PRIMARY KEY ("id")
);
