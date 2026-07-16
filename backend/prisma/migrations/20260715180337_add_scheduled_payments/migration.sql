-- CreateEnum
CREATE TYPE "ScheduledPaymentType" AS ENUM ('RENT', 'ELECTRICITY', 'WATER', 'INTERNET', 'MOBILE_RECHARGE', 'SUBSCRIPTION', 'EMI', 'INSURANCE', 'SAVINGS', 'CUSTOM');

-- CreateEnum
CREATE TYPE "ScheduledPaymentFrequency" AS ENUM ('DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY', 'CUSTOM');

-- CreateEnum
CREATE TYPE "ScheduledPaymentStatus" AS ENUM ('ACTIVE', 'PAUSED', 'COMPLETED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "ScheduledPaymentExecutionStatus" AS ENUM ('SUCCESS', 'FAILED');

-- CreateTable
CREATE TABLE "ScheduledPayment" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "paymentType" "ScheduledPaymentType" NOT NULL DEFAULT 'CUSTOM',
    "amount" DECIMAL(14,2) NOT NULL,
    "frequency" "ScheduledPaymentFrequency" NOT NULL,
    "customIntervalDays" INTEGER,
    "purposeWalletId" TEXT NOT NULL,
    "merchantId" TEXT,
    "receiverUserId" TEXT,
    "note" TEXT,
    "startDate" TIMESTAMP(3) NOT NULL,
    "nextExecution" TIMESTAMP(3) NOT NULL,
    "lastExecution" TIMESTAMP(3),
    "lastReminderFor" TIMESTAMP(3),
    "endDate" TIMESTAMP(3),
    "status" "ScheduledPaymentStatus" NOT NULL DEFAULT 'ACTIVE',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ScheduledPayment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ScheduledPaymentExecution" (
    "id" TEXT NOT NULL,
    "scheduledPaymentId" TEXT NOT NULL,
    "scheduledFor" TIMESTAMP(3) NOT NULL,
    "executedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "status" "ScheduledPaymentExecutionStatus" NOT NULL,
    "amount" DECIMAL(14,2) NOT NULL,
    "failureReason" TEXT,
    "paymentId" TEXT,

    CONSTRAINT "ScheduledPaymentExecution_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "ScheduledPayment" ADD CONSTRAINT "ScheduledPayment_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ScheduledPayment" ADD CONSTRAINT "ScheduledPayment_purposeWalletId_fkey" FOREIGN KEY ("purposeWalletId") REFERENCES "PurposeWallet"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ScheduledPayment" ADD CONSTRAINT "ScheduledPayment_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES "Merchant"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ScheduledPayment" ADD CONSTRAINT "ScheduledPayment_receiverUserId_fkey" FOREIGN KEY ("receiverUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ScheduledPaymentExecution" ADD CONSTRAINT "ScheduledPaymentExecution_scheduledPaymentId_fkey" FOREIGN KEY ("scheduledPaymentId") REFERENCES "ScheduledPayment"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
