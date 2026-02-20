/*
  Warnings:

  - A unique constraint covering the columns `[userId,productId]` on the table `reviews` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateEnum
CREATE TYPE "NotificationType" AS ENUM ('PRODUCT_APPROVED', 'PRODUCT_REJECTED', 'PRODUCT_PENDING', 'SIMILAR_PRODUCT_POSTED', 'MESSAGE_RECEIVED', 'MESSAGE_READ', 'CONVERSATION_REPLY', 'ORDER_CONFIRMED', 'ORDER_SHIPPED', 'ORDER_DELIVERED', 'NEW_ORDER_RECEIVED', 'PAYMENT_RECEIVED', 'RATING_REQUEST', 'WELCOME', 'SECURITY_ALERT', 'PROMOTION');

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "fcmToken" TEXT;

-- CreateTable
CREATE TABLE "notifications" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "type" "NotificationType" NOT NULL,
    "data" JSONB,
    "isRead" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "notifications_userId_idx" ON "notifications"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "reviews_userId_productId_key" ON "reviews"("userId", "productId");

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
