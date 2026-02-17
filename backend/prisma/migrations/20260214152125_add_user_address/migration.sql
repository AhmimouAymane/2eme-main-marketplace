/*
  Warnings:

  - The values [DRAFT] on the enum `ProductStatus` will be removed. If these variants are still used in the database, this will fail.

*/
-- AlterEnum
BEGIN;
CREATE TYPE "ProductStatus_new" AS ENUM ('PENDING_APPROVAL', 'FOR_SALE', 'REJECTED', 'RESERVED', 'SOLD');
ALTER TABLE "products" ALTER COLUMN "status" DROP DEFAULT;
ALTER TABLE "products" ALTER COLUMN "status" TYPE "ProductStatus_new" USING ("status"::text::"ProductStatus_new");
ALTER TYPE "ProductStatus" RENAME TO "ProductStatus_old";
ALTER TYPE "ProductStatus_new" RENAME TO "ProductStatus";
DROP TYPE "ProductStatus_old";
ALTER TABLE "products" ALTER COLUMN "status" SET DEFAULT 'PENDING_APPROVAL';
COMMIT;

-- AlterTable
ALTER TABLE "products" ADD COLUMN     "moderationComment" TEXT,
ALTER COLUMN "status" SET DEFAULT 'PENDING_APPROVAL';

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "address" TEXT;
