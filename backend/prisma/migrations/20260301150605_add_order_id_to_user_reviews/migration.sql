/*
  Warnings:

  - The values [PENDING,OFFER_PENDING,OFFER_REJECTED] on the enum `OrderStatus` will be removed. If these variants are still used in the database, this will fail.
  - The values [FOR_SALE] on the enum `ProductStatus` will be removed. If these variants are still used in the database, this will fail.
  - A unique constraint covering the columns `[orderId,reviewerId]` on the table `user_reviews` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `orderId` to the `user_reviews` table without a default value. This is not possible if the table is not empty.

*/
-- AlterEnum
BEGIN;
CREATE TYPE "OrderStatus_new" AS ENUM ('OFFER_MADE', 'AWAITING_SELLER_CONFIRMATION', 'CONFIRMED', 'SHIPPED', 'DELIVERED', 'RETURN_WINDOW_48H', 'RETURN_REQUESTED', 'RETURNED', 'CANCELLED', 'COMPLETED');
ALTER TABLE "orders" ALTER COLUMN "status" DROP DEFAULT;
ALTER TABLE "orders" ALTER COLUMN "status" TYPE "OrderStatus_new" USING ("status"::text::"OrderStatus_new");
ALTER TYPE "OrderStatus" RENAME TO "OrderStatus_old";
ALTER TYPE "OrderStatus_new" RENAME TO "OrderStatus";
DROP TYPE "OrderStatus_old";
ALTER TABLE "orders" ALTER COLUMN "status" SET DEFAULT 'AWAITING_SELLER_CONFIRMATION';
COMMIT;

-- AlterEnum
BEGIN;
CREATE TYPE "ProductStatus_new" AS ENUM ('PENDING_APPROVAL', 'PUBLISHED', 'REJECTED', 'RESERVED', 'CONFIRMED', 'SOLD');
ALTER TABLE "products" ALTER COLUMN "status" DROP DEFAULT;
ALTER TABLE "products" ALTER COLUMN "status" TYPE "ProductStatus_new" USING ("status"::text::"ProductStatus_new");
ALTER TYPE "ProductStatus" RENAME TO "ProductStatus_old";
ALTER TYPE "ProductStatus_new" RENAME TO "ProductStatus";
DROP TYPE "ProductStatus_old";
ALTER TABLE "products" ALTER COLUMN "status" SET DEFAULT 'PENDING_APPROVAL';
COMMIT;

-- DropIndex
DROP INDEX "user_reviews_reviewerId_targetUserId_key";

-- AlterTable
ALTER TABLE "addresses" ADD COLUMN     "phone" TEXT;

-- AlterTable
ALTER TABLE "orders" ADD COLUMN     "cancellationReason" TEXT,
ADD COLUMN     "completedAt" TIMESTAMP(3),
ADD COLUMN     "confirmedAt" TIMESTAMP(3),
ADD COLUMN     "expiresAt" TIMESTAMP(3),
ADD COLUMN     "returnReason" TEXT,
ADD COLUMN     "returnRequestedAt" TIMESTAMP(3),
ADD COLUMN     "returnedAt" TIMESTAMP(3),
ADD COLUMN     "shippedAt" TIMESTAMP(3),
ALTER COLUMN "status" SET DEFAULT 'AWAITING_SELLER_CONFIRMATION';

-- AlterTable
ALTER TABLE "user_reviews" ADD COLUMN     "orderId" TEXT NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "user_reviews_orderId_reviewerId_key" ON "user_reviews"("orderId", "reviewerId");

-- AddForeignKey
ALTER TABLE "user_reviews" ADD CONSTRAINT "user_reviews_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;
