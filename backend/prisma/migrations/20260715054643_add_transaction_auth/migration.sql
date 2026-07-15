-- CreateEnum
CREATE TYPE "TransactionAuthStatus" AS ENUM ('PENDING_FINGERPRINT', 'FINGERPRINT_CONFIRMED', 'OTP_SENT', 'OTP_VERIFIED', 'COMPLETED', 'EXPIRED', 'CANCELLED');

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "phoneNumber" TEXT;

-- CreateTable
CREATE TABLE "TransactionAuthSession" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "deviceId" TEXT NOT NULL,
    "purposeWalletId" TEXT NOT NULL,
    "amount" DECIMAL(14,2) NOT NULL,
    "status" "TransactionAuthStatus" NOT NULL DEFAULT 'PENDING_FINGERPRINT',
    "otpAttempts" INTEGER NOT NULL DEFAULT 0,
    "fingerprintConfirmedAt" TIMESTAMP(3),
    "otpSentAt" TIMESTAMP(3),
    "otpVerifiedAt" TIMESTAMP(3),
    "completedAt" TIMESTAMP(3),
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TransactionAuthSession_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "TransactionAuthSession" ADD CONSTRAINT "TransactionAuthSession_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
