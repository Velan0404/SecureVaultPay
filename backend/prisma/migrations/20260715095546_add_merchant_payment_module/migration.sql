-- CreateEnum
CREATE TYPE "MerchantCategory" AS ENUM ('GROCERY', 'FOOD', 'FUEL', 'SHOPPING', 'ENTERTAINMENT', 'HEALTHCARE', 'EDUCATION', 'UTILITY', 'TRAVEL', 'OTHER');

-- CreateEnum
CREATE TYPE "MerchantStatus" AS ENUM ('ACTIVE', 'INACTIVE');

-- CreateEnum
CREATE TYPE "MerchantPaymentStatus" AS ENUM ('SUCCESS', 'FAILED');

-- AlterTable
ALTER TABLE "TransactionAuthSession" ADD COLUMN     "merchantId" TEXT;

-- CreateTable
CREATE TABLE "Merchant" (
    "id" TEXT NOT NULL,
    "merchantName" TEXT NOT NULL,
    "merchantCategory" "MerchantCategory" NOT NULL,
    "merchantCode" TEXT NOT NULL,
    "merchantLogo" TEXT,
    "status" "MerchantStatus" NOT NULL DEFAULT 'ACTIVE',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Merchant_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MerchantPayment" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "purposeWalletId" TEXT NOT NULL,
    "merchantId" TEXT NOT NULL,
    "amount" DECIMAL(14,2) NOT NULL,
    "status" "MerchantPaymentStatus" NOT NULL DEFAULT 'SUCCESS',
    "transactionAuthSessionId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "MerchantPayment_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Merchant_merchantCode_key" ON "Merchant"("merchantCode");

-- AddForeignKey
ALTER TABLE "TransactionAuthSession" ADD CONSTRAINT "TransactionAuthSession_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES "Merchant"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MerchantPayment" ADD CONSTRAINT "MerchantPayment_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MerchantPayment" ADD CONSTRAINT "MerchantPayment_purposeWalletId_fkey" FOREIGN KEY ("purposeWalletId") REFERENCES "PurposeWallet"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MerchantPayment" ADD CONSTRAINT "MerchantPayment_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES "Merchant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
