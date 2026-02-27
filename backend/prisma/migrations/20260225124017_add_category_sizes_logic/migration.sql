-- CreateEnum
CREATE TYPE "VerificationType" AS ENUM ('REGISTRATION', 'PASSWORD_RESET');

-- AlterTable
ALTER TABLE "categories" ADD COLUMN     "possibleSizes" TEXT[];

-- AlterTable
ALTER TABLE "products" ADD COLUMN     "document_id" VARCHAR(255),
ADD COLUMN     "locale" VARCHAR(255),
ADD COLUMN     "published_at" VARCHAR(255);

-- AlterTable
ALTER TABLE "reviews" ADD COLUMN     "document_id" VARCHAR(255),
ADD COLUMN     "locale" VARCHAR(255),
ADD COLUMN     "published_at" VARCHAR(255);

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "document_id" VARCHAR(255),
ADD COLUMN     "isEmailVerified" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "locale" VARCHAR(255),
ADD COLUMN     "published_at" VARCHAR(255);

-- CreateTable
CREATE TABLE "verification_codes" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "type" "VerificationType" NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "verification_codes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "strapi_migrations" (
    "id" SERIAL NOT NULL,
    "name" VARCHAR(255),
    "time" TIMESTAMP(6),

    CONSTRAINT "strapi_migrations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "strapi_migrations_internal" (
    "id" SERIAL NOT NULL,
    "name" VARCHAR(255),
    "time" TIMESTAMP(6),

    CONSTRAINT "strapi_migrations_internal_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "verification_codes_email_idx" ON "verification_codes"("email");

-- CreateIndex
CREATE INDEX "products_deletedAt_idx" ON "products"("deletedAt");
