import { Injectable, Inject } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateUserDto } from './dto/create-user.dto';
import { User, Prisma, NotificationType } from '@prisma/client';
import { ModerationService } from '../moderation/moderation.service';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class UsersService {
    constructor(
        private prisma: PrismaService,
        @Inject('FIREBASE_ADMIN') private firebaseAdmin: any,
        private moderationService: ModerationService,
        private notificationsService: NotificationsService,
    ) { }

    async findAll(query: { _start?: number, _end?: number }) {
        const where = {};
        const total = await this.prisma.user.count({ where });
        const users = await this.prisma.user.findMany({
            where,
            skip: query._start ? Number(query._start) : undefined,
            take: (query._end && query._start) ? (Number(query._end) - Number(query._start)) : undefined,
            orderBy: { createdAt: 'desc' },
        });

        return {
            data: users.map(user => {
                const { password, ...userData } = user;
                return userData;
            }),
            total
        };
    }

    async search(searchTerm: string) {
        if (!searchTerm) return [];

        return this.prisma.user.findMany({
            where: {
                OR: [
                    { firstName: { contains: searchTerm, mode: 'insensitive' } },
                    { lastName: { contains: searchTerm, mode: 'insensitive' } },
                ],
            },
            select: {
                id: true,
                firstName: true,
                lastName: true,
                avatarUrl: true,
            },
            take: 20,
        });
    }

    async findOne(id: string, includeProducts = false, isPublic = false, viewerId?: string) {
        if (viewerId && viewerId !== id) {
            const isBlocked = await this.moderationService.isBlocked(viewerId, id);
            if (isBlocked) return null;
        }

        const user = await this.prisma.user.findUnique({
            where: { id },
            include: {
                products: includeProducts ? {
                    where: {
                        deletedAt: null,
                        ...(isPublic ? { status: 'PUBLISHED' } : {})
                    },
                    include: {
                        images: true,
                        category: true,
                    },
                    orderBy: {
                        createdAt: 'desc',
                    },
                } : false,
                receivedReviews: {
                    include: {
                        reviewer: true
                    },
                    orderBy: {
                        createdAt: 'desc'
                    }
                },
                givenReviews: {
                    include: {
                        targetUser: true
                    },
                    orderBy: {
                        createdAt: 'desc'
                    }
                },
                _count: {
                    select: {
                        sellerOrders: {
                            where: {
                                status: {
                                    in: ['CONFIRMED', 'SHIPPED', 'DELIVERED', 'RETURN_WINDOW_48H', 'COMPLETED']
                                }
                            }
                        }
                    }
                },
            },
        });

        if (!user) return null;

        // Calculate average rating
        const anyUser = user as any;
        const totalRating = anyUser.receivedReviews.reduce((sum: number, review: any) => sum + review.rating, 0);
        const averageRating = anyUser.receivedReviews.length > 0
            ? totalRating / anyUser.receivedReviews.length
            : 0;

        const { password, _count, receivedReviews: rr, givenReviews: gr, products: pr, ...userData } = anyUser;

        return {
            ...userData,
            averageRating,
            salesCount: _count.sellerOrders,
            products: pr || [],
            receivedReviews: (rr || []).map((r: any) => {
                const { reviewer, ...reviewData } = r;
                return {
                    ...reviewData,
                    reviewer: reviewer ? {
                        id: reviewer.id,
                        firstName: reviewer.firstName,
                        lastName: reviewer.lastName,
                        avatarUrl: reviewer.avatarUrl,
                    } : null,
                };
            }),
            givenReviews: (gr || []).map((r: any) => {
                const { targetUser, ...reviewData } = r;
                return {
                    ...reviewData,
                    targetUser: targetUser ? {
                        id: targetUser.id,
                        firstName: targetUser.firstName,
                        lastName: targetUser.lastName,
                        avatarUrl: targetUser.avatarUrl,
                    } : null,
                };
            }),
        };
    }

    async findByEmail(email: string): Promise<User | null> {
        return this.prisma.user.findUnique({
            where: { email },
        });
    }

    async create(data: CreateUserDto): Promise<User> {
        return this.prisma.user.create({
            data: {
                ...data,
                role: 'USER',
            },
        });
    }

    async update(id: string, data: Prisma.UserUpdateInput): Promise<User> {
        return this.prisma.user.update({
            where: { id },
            data,
        });
    }

    async remove(id: string): Promise<User> {
        // 1. Find user first to get email
        const user = await this.prisma.user.findUnique({ where: { id } });

        if (user) {
            // 2. Try to delete from Firebase Auth
            try {
                const firebaseUser = await this.firebaseAdmin.auth().getUserByEmail(user.email);
                await this.firebaseAdmin.auth().deleteUser(firebaseUser.uid);
            } catch (error) {
                // Log error but continue with DB deletion (user might already be deleted in Firebase)
                console.warn(`Could not delete Firebase user for email ${user.email}:`, error);
            }
        }

        // 3. Delete from database
        return this.prisma.user.delete({
            where: { id },
        });
    }

    async rateUser(reviewerId: string, targetUserId: string, rating: number, comment?: string) {
        const review = await (this.prisma as any).userReview.upsert({
            where: {
                reviewerId_targetUserId: {
                    reviewerId,
                    targetUserId,
                },
            },
            update: {
                rating,
                comment,
            },
            create: {
                reviewerId,
                targetUserId,
                rating,
                comment,
            },
        });

        const reviewer = await this.prisma.user.findUnique({
            where: { id: reviewerId },
            select: { firstName: true }
        });

        if (reviewerId !== targetUserId) {
            await this.notificationsService.create({
                userId: targetUserId,
                title: '⭐ Nouvelle évaluation reçue !',
                message: `${reviewer?.firstName || 'Quelqu\'un'} vous a laissé une évaluation de ${rating} étoile(s).`,
                type: NotificationType.NEW_REVIEW_RECEIVED,
                data: { screen: 'profile' },
            });
        }

        return review;
    }
}
