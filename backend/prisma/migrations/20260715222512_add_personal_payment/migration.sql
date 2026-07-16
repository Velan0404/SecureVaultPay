-- AlterEnum
ALTER TYPE "WalletTransactionType" ADD VALUE 'PERSONAL_PAYMENT_SENT';
ALTER TYPE "WalletTransactionType" ADD VALUE 'PERSONAL_PAYMENT_RECEIVED';

-- AlterTable
ALTER TABLE "User" ADD COLUMN "secureVaultId" TEXT;

-- CreateTable
CREATE TABLE "PersonalPayment" (
    "id" TEXT NOT NULL,
    "senderId" TEXT NOT NULL,
    "receiverId" TEXT NOT NULL,
    "senderPurposeWalletId" TEXT NOT NULL,
    "amount" DECIMAL(14,2) NOT NULL,
    "note" TEXT,
    "status" "MerchantPaymentStatus" NOT NULL DEFAULT 'SUCCESS',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PersonalPayment_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_secureVaultId_key" ON "User"("secureVaultId");

-- AddForeignKey
ALTER TABLE "PersonalPayment" ADD CONSTRAINT "PersonalPayment_senderId_fkey" FOREIGN KEY ("senderId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PersonalPayment" ADD CONSTRAINT "PersonalPayment_receiverId_fkey" FOREIGN KEY ("receiverId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PersonalPayment" ADD CONSTRAINT "PersonalPayment_senderPurposeWalletId_fkey" FOREIGN KEY ("senderPurposeWalletId") REFERENCES "PurposeWallet"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
