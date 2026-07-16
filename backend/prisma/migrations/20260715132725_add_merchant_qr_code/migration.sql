-- CreateEnum
CREATE TYPE "MerchantQrStatus" AS ENUM ('ACTIVE', 'USED', 'EXPIRED');

-- CreateTable
CREATE TABLE "MerchantQrCode" (
    "id" TEXT NOT NULL,
    "merchantId" TEXT NOT NULL,
    "status" "MerchantQrStatus" NOT NULL DEFAULT 'ACTIVE',
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "usedAt" TIMESTAMP(3),
    "merchantPaymentId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "MerchantQrCode_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "MerchantQrCode" ADD CONSTRAINT "MerchantQrCode_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES "Merchant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
