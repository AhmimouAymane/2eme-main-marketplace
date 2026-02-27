import { Injectable, Inject } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateUserDto } from './dto/create-user.dto';
import { User, Prisma } from '@prisma/client';

@Injectable()
export class UsersService {
    constructor(
        private prisma: PrismaService,
        @Inject('FIREBASE_ADMIN') private firebaseAdmin: any,
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

    async findOne(id: string, includeProducts = false) {
        const user = await this.prisma.user.findUnique({
            where: { id },
            include: {
                products: includeProducts ? {
                    where: { deletedAt: null },
                    include: {
                        images: true,
                        category: true,
                    },
                    orderBy: {
                        createdAt: 'desc',
                    },
                } : false,
                receivedReviews: true,
                _count: {
                    select: {
                        sellerOrders: {
                            where: { status: 'DELIVERED' }
                        }
                    }
                }
            },
        });

        if (!user) return null;

        // Calculate average rating
        const anyUser = user as any;
        const totalRating = anyUser.receivedReviews.reduce((sum: number, review: any) => sum + review.rating, 0);
        const averageRating = anyUser.receivedReviews.length > 0
            ? totalRating / anyUser.receivedReviews.length
            : 0;

        const { password, receivedReviews, _count, ...userData } = anyUser;

        return {
            ...userData,
            averageRating,
            salesCount: _count.sellerOrders,
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
        return (this.prisma as any).userReview.upsert({
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
    }
}
