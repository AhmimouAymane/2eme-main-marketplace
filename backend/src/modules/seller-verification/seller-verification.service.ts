import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SellerStatus, NotificationType } from '@prisma/client';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class SellerVerificationService {
    constructor(
        private prisma: PrismaService,
        private notificationsService: NotificationsService,
    ) { }

    async submitVerification(userId: string, files: {
        idCardFront?: any;
        idCardBack?: any;
        bankCertificate?: any
    }) {
        const user = await this.prisma.user.findUnique({ where: { id: userId } });
        if (!user) throw new NotFoundException('User not found');

        if (user.sellerStatus === SellerStatus.APPROVED) {
            throw new BadRequestException('Seller already verified');
        }

        const transactionSteps = [];

        if (files.idCardFront) {
            transactionSteps.push(
                this.prisma.verificationDocument.create({
                    data: {
                        userId,
                        fileType: 'ID_CARD_FRONT',
                        fileName: files.idCardFront.originalname,
                        mimeType: files.idCardFront.mimetype,
                        fileData: files.idCardFront.buffer,
                    },
                }),
            );
        }

        if (files.idCardBack) {
            transactionSteps.push(
                this.prisma.verificationDocument.create({
                    data: {
                        userId,
                        fileType: 'ID_CARD_BACK',
                        fileName: files.idCardBack.originalname,
                        mimeType: files.idCardBack.mimetype,
                        fileData: files.idCardBack.buffer,
                    },
                }),
            );
        }

        if (files.bankCertificate) {
            transactionSteps.push(
                this.prisma.verificationDocument.create({
                    data: {
                        userId,
                        fileType: 'BANK_CERTIFICATE',
                        fileName: files.bankCertificate.originalname,
                        mimeType: files.bankCertificate.mimetype,
                        fileData: files.bankCertificate.buffer,
                    },
                }),
            );
        }

        transactionSteps.push(
            this.prisma.user.update({
                where: { id: userId },
                data: {
                    sellerStatus: SellerStatus.PENDING,
                },
            }),
        );

        await this.prisma.$transaction(transactionSteps);
        return { message: 'Verification documents submitted successfully' };
    }

    async getStatus(userId: string) {
        const user = await this.prisma.user.findUnique({
            where: { id: userId },
            select: {
                sellerStatus: true,
                verificationComment: true,
                isSellerVerified: true,
                verificationDocuments: {
                    select: {
                        id: true,
                        fileType: true,
                        fileName: true,
                        createdAt: true,
                    },
                    orderBy: {
                        createdAt: 'desc'
                    }
                },
            },
        });
        if (!user) throw new NotFoundException('User not found');
        return user;
    }

    async getDocument(docId: string) {
        const doc = await this.prisma.verificationDocument.findUnique({
            where: { id: docId },
        });
        if (!doc) throw new NotFoundException('Document not found');
        return doc;
    }

    async approve(userId: string) {
        const user = await this.prisma.user.update({
            where: { id: userId },
            data: {
                isSellerVerified: true,
                sellerStatus: SellerStatus.APPROVED,
                verificationComment: null,
            },
        });

        // Send notification
        await this.notificationsService.create({
            userId,
            title: 'Compte Vendeur Approuvé !',
            message: 'Félicitations, votre compte vendeur a été validé. Vous pouvez maintenant poster des articles.',
            type: NotificationType.SELLER_VERIFIED,
            data: { newStatus: 'APPROVED' },
        });

        return user;
    }

    async reject(userId: string, comment: string) {
        const user = await this.prisma.user.update({
            where: { id: userId },
            data: {
                isSellerVerified: false,
                sellerStatus: SellerStatus.REJECTED,
                verificationComment: comment,
            },
        });

        // Send notification
        await this.notificationsService.create({
            userId,
            title: 'Vérification Vendeur Refusée',
            message: `Votre demande a été refusée. Motif : ${comment}`,
            type: NotificationType.SELLER_REJECTED,
            data: { newStatus: 'REJECTED' },
        });

        return user;
    }

    async findAllByStatus(status: SellerStatus) {
        console.log(`[Service] Querying database for sellerStatus: ${status}`);
        const results = await this.prisma.user.findMany({
            where: status === 'APPROVED' as any
                ? { OR: [{ sellerStatus: 'APPROVED' as any }, { isSellerVerified: true }] }
                : { sellerStatus: status },
            select: {
                id: true,
                firstName: true,
                lastName: true,
                email: true,
                createdAt: true,
                sellerStatus: true,
                isSellerVerified: true,
                verificationDocuments: {
                    select: {
                        id: true,
                        fileType: true,
                        fileName: true,
                    },
                },
            },
        });
        console.log(`[Service] Found ${results.length} users for status ${status}`);
        return results;
    }

    async findAllPending() {
        return this.findAllByStatus(SellerStatus.PENDING);
    }
}
