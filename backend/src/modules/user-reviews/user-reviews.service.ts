import { Injectable, BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateUserReviewDto } from './dto/create-user-review.dto';
import { OrderStatus, NotificationType } from '@prisma/client';

@Injectable()
export class UserReviewsService {
    constructor(
        private readonly prisma: PrismaService,
    ) { }

    async create(userId: string, dto: CreateUserReviewDto) {
        const { orderId, rating, comment } = dto;

        // 1. Find the order
        const order = await this.prisma.order.findUnique({
            where: { id: orderId },
            include: { product: true }
        });

        if (!order) throw new NotFoundException('Commande introuvable.');
        if (order.status !== OrderStatus.COMPLETED) {
            throw new BadRequestException('Vous ne pouvez évaluer qu\'une commande terminée.');
        }

        // 2. Verify user is part of the order
        const isBuyer = order.buyerId === userId;
        const isSeller = order.sellerId === userId;
        if (!isBuyer && !isSeller) {
            throw new ForbiddenException('Vous n\'êtes pas autorisé à évaluer cette commande.');
        }

        // 3. Determine target user
        const targetUserId = isBuyer ? order.sellerId : order.buyerId;

        // 4. Check if already rated (using new unique constraint: one review per user pair)
        const existingReview = await (this.prisma as any).userReview.findUnique({
            where: { reviewerId_targetUserId: { reviewerId: userId, targetUserId } },
        });
        if (existingReview) {
            throw new BadRequestException('Vous avez déjà évalué cet utilisateur.');
        }

        // 5. Create review
        const review = await (this.prisma as any).userReview.create({
            data: {
                orderId: orderId || null,
                reviewerId: userId,
                targetUserId,
                rating,
                comment
            },
            include: { reviewer: { select: { firstName: true, lastName: true } } },
        });

        // 6. Save notification to DB (without push notification to avoid Firebase dependency)
        try {
            await this.prisma.notification.create({
                data: {
                    userId: targetUserId,
                    title: '⭐ Nouvel avis reçu !',
                    message: `${review.reviewer.firstName} vous a laissé une note de ${rating}/5.`,
                    type: NotificationType.RATING_REQUEST,
                    data: { orderId, screen: 'order_detail' },
                },
            });
        } catch (e) {
            // Non-blocking: notification failure doesn't fail the review
            console.error('Failed to create notification for review:', e);
        }

        return review;
    }

    async getReviewsForUser(targetUserId: string) {
        return this.prisma.userReview.findMany({
            where: { targetUserId },
            include: {
                reviewer: {
                    select: { id: true, firstName: true, lastName: true, avatarUrl: true },
                },
            },
            orderBy: { createdAt: 'desc' },
        });
    }

    async getReviewForOrder(orderId: string, reviewerId: string) {
        return (this.prisma as any).userReview.findFirst({
            where: { orderId, reviewerId },
        });
    }

    async getTopSellers(limit = 10) {
        try {
            // Fetch all users with at least one published product
            const sellers = await this.prisma.user.findMany({
                where: {
                    products: { some: { status: 'PUBLISHED' } },
                },
                include: {
                    receivedReviews: true,
                    products: {
                        where: { status: 'PUBLISHED' },
                        select: { id: true },
                    },
                },
            });

            // Calculate metrics and sort
            return sellers
                .map((user) => {
                    const reviews = user.receivedReviews || [];
                    const totalRating = reviews.reduce((sum, r) => sum + (r.rating || 0), 0);
                    const averageRating = reviews.length > 0 ? totalRating / reviews.length : 0;
                    return {
                        id: user.id,
                        firstName: user.firstName,
                        lastName: user.lastName,
                        avatarUrl: user.avatarUrl,
                        averageRating,
                        reviewCount: reviews.length,
                        activeProductsCount: user.products?.length || 0,
                    };
                })
                .sort((a, b) =>
                    b.averageRating - a.averageRating ||
                    b.reviewCount - a.reviewCount ||
                    b.activeProductsCount - a.activeProductsCount
                )
                .slice(0, limit);
        } catch (error) {
            console.error('Error in getTopSellers:', error);
            throw error;
        }
    }
}
