/*
  Warnings:

  - A unique constraint covering the columns `[reviewerId,targetUserId]` on the table `user_reviews` will be added. If there are existing duplicate values, this will fail.

*/
-- DropIndex
DROP INDEX "user_reviews_orderId_reviewerId_key";

-- AlterTable
ALTER TABLE "user_reviews" ALTER COLUMN "orderId" DROP NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "user_reviews_reviewerId_targetUserId_key" ON "user_reviews"("reviewerId", "targetUserId");
