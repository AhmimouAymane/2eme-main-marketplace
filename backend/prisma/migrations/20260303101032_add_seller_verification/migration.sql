-- CreateEnum
CREATE TYPE "SellerStatus" AS ENUM ('NOT_SUBMITTED', 'PENDING', 'APPROVED', 'REJECTED');

-- AlterTable
ALTER TABLE "conversations" ADD COLUMN     "deletedByBuyer" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "deletedBySeller" BOOLEAN NOT NULL DEFAULT false;

-- AlterTable
ALTER TABLE "orders" ADD COLUMN     "serviceFee" DOUBLE PRECISION NOT NULL DEFAULT 0,
ADD COLUMN     "shippingFee" DOUBLE PRECISION NOT NULL DEFAULT 0;

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "bankCertificateUrl" TEXT,
ADD COLUMN     "idCardUrl" TEXT,
ADD COLUMN     "isSellerVerified" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "sellerStatus" "SellerStatus" NOT NULL DEFAULT 'NOT_SUBMITTED',
ADD COLUMN     "verificationComment" TEXT;

-- CreateTable
CREATE TABLE "system_settings" (
    "id" TEXT NOT NULL DEFAULT 'default',
    "serviceFeePercentage" DOUBLE PRECISION NOT NULL DEFAULT 5.0,
    "shippingFee" DOUBLE PRECISION NOT NULL DEFAULT 25.0,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "system_settings_pkey" PRIMARY KEY ("id")
);
