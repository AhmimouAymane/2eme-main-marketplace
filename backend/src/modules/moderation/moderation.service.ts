import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ReportReason } from '@prisma/client';

@Injectable()
export class ModerationService {
    constructor(private prisma: PrismaService) { }

    async reportContent(
        reporterId: string,
        data: {
            reason: ReportReason;
            description?: string;
            reportedUserId?: string;
            reportedProductId?: string;
            reportedCommentId?: string;
        },
    ) {
        if (!data.reportedUserId && !data.reportedProductId && !data.reportedCommentId) {
            throw new BadRequestException('Vous devez signaler un utilisateur, un produit ou un commentaire.');
        }

        return this.prisma.report.create({
            data: {
                reporterId,
                reason: data.reason,
                description: data.description,
                reportedUserId: data.reportedUserId,
                reportedProductId: data.reportedProductId,
                reportedCommentId: data.reportedCommentId,
            },
        });
    }

    async getAllReports() {
        return this.prisma.report.findMany({
            orderBy: { createdAt: 'desc' },
            include: {
                reporter: {
                    select: { id: true, firstName: true, lastName: true, avatarUrl: true },
                },
                reportedUser: {
                    select: { id: true, firstName: true, lastName: true, avatarUrl: true },
                },
                reportedProduct: {
                    select: { id: true, title: true },
                },
                reportedComment: {
                    select: { id: true, content: true },
                },
            },
        });
    }

    async blockUser(blockerId: string, blockedUserId: string) {
        if (blockerId === blockedUserId) {
            throw new BadRequestException('Vous ne pouvez pas vous bloquer vous-même.');
        }

        return this.prisma.block.upsert({
            where: {
                blockerId_blockedUserId: {
                    blockerId,
                    blockedUserId,
                },
            },
            update: {},
            create: {
                blockerId,
                blockedUserId,
            },
        });
    }

    async unblockUser(blockerId: string, blockedUserId: string) {
        return this.prisma.block.delete({
            where: {
                blockerId_blockedUserId: {
                    blockerId,
                    blockedUserId,
                },
            },
        });
    }

    async getBlockedUsers(userId: string) {
        return this.prisma.block.findMany({
            where: { blockerId: userId },
            include: {
                blockedUser: {
                    select: {
                        id: true,
                        firstName: true,
                        lastName: true,
                        avatarUrl: true,
                    },
                },
            },
        });
    }

    async isBlocked(userAId: string, userBId: string): Promise<boolean> {
        const block = await this.prisma.block.findFirst({
            where: {
                OR: [
                    { blockerId: userAId, blockedUserId: userBId },
                    { blockerId: userBId, blockedUserId: userAId },
                ],
            },
        });
        return !!block;
    }

    async getAllBlockedUserIds(userId: string): Promise<string[]> {
        const blocks = await this.prisma.block.findMany({
            where: {
                OR: [
                    { blockerId: userId },
                    { blockedUserId: userId }
                ]
            },
            select: {
                blockerId: true,
                blockedUserId: true
            }
        });

        const blockedIds = new Set<string>();
        for (const block of blocks) {
            if (block.blockerId !== userId) blockedIds.add(block.blockerId);
            if (block.blockedUserId !== userId) blockedIds.add(block.blockedUserId);
        }

        return Array.from(blockedIds);
    }
}
