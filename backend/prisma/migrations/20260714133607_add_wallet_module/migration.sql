-- CreateEnum
CREATE TYPE "PurposeWalletStatus" AS ENUM ('ACTIVE', 'ARCHIVED');

-- CreateEnum
CREATE TYPE "WalletTransactionType" AS ENUM ('WALLET_CREATED', 'WALLET_UPDATED', 'WALLET_DELETED', 'DEMO_LOAD', 'MAIN_TO_PURPOSE', 'PURPOSE_TO_MAIN', 'PURPOSE_PAYMENT', 'REFUND', 'ADJUSTMENT');

-- CreateEnum
CREATE TYPE "WalletTransactionStatus" AS ENUM ('SUCCESS', 'FAILED');

-- CreateTable
CREATE TABLE "MainWallet" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "balance" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "MainWallet_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PurposeWallet" (
    "id" TEXT NOT NULL,
    "mainWalletId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "icon" TEXT NOT NULL,
    "color" TEXT NOT NULL,
    "purpose" TEXT,
    "balance" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "spendingLimit" DECIMAL(14,2),
    "status" "PurposeWalletStatus" NOT NULL DEFAULT 'ACTIVE',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PurposeWallet_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WalletTransfer" (
    "id" TEXT NOT NULL,
    "mainWalletId" TEXT NOT NULL,
    "purposeWalletId" TEXT NOT NULL,
    "amount" DECIMAL(14,2) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "WalletTransfer_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WalletTransaction" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "mainWalletId" TEXT,
    "purposeWalletId" TEXT,
    "type" "WalletTransactionType" NOT NULL,
    "amount" DECIMAL(14,2) NOT NULL,
    "source" TEXT,
    "destination" TEXT,
    "description" TEXT,
    "status" "WalletTransactionStatus" NOT NULL DEFAULT 'SUCCESS',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "WalletTransaction_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "MainWallet_userId_key" ON "MainWallet"("userId");

-- AddForeignKey
ALTER TABLE "MainWallet" ADD CONSTRAINT "MainWallet_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PurposeWallet" ADD CONSTRAINT "PurposeWallet_mainWalletId_fkey" FOREIGN KEY ("mainWalletId") REFERENCES "MainWallet"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WalletTransfer" ADD CONSTRAINT "WalletTransfer_mainWalletId_fkey" FOREIGN KEY ("mainWalletId") REFERENCES "MainWallet"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WalletTransfer" ADD CONSTRAINT "WalletTransfer_purposeWalletId_fkey" FOREIGN KEY ("purposeWalletId") REFERENCES "PurposeWallet"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WalletTransaction" ADD CONSTRAINT "WalletTransaction_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WalletTransaction" ADD CONSTRAINT "WalletTransaction_mainWalletId_fkey" FOREIGN KEY ("mainWalletId") REFERENCES "MainWallet"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WalletTransaction" ADD CONSTRAINT "WalletTransaction_purposeWalletId_fkey" FOREIGN KEY ("purposeWalletId") REFERENCES "PurposeWallet"("id") ON DELETE SET NULL ON UPDATE CASCADE;
