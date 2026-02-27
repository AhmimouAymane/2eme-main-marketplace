import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../prisma/prisma.service';
import { ProductStatus, OrderStatus } from '@prisma/client';

@Injectable()
export class OrderExpirationService {
    private readonly logger = new Logger(OrderExpirationService.name);

    constructor(private prisma: PrismaService) { }

    // Run every 15 minutes to check for expired reservations
    @Cron('0 */15 * * * *')
    async handleExpiredReservations() {
        this.logger.debug('Checking for expired product reservations...');

        const twoHoursAgo = new Date();
        twoHoursAgo.setHours(twoHoursAgo.getHours() - 2);

        // Find orders that are still AWAITING_SELLER_CONFIRMATION and were created more than 2 hours ago
        const expiredOrders = await this.prisma.order.findMany({
            where: {
                status: OrderStatus.AWAITING_SELLER_CONFIRMATION,
                createdAt: {
                    lt: twoHoursAgo,
                },
            },
            include: {
                product: true,
            },
        });

        if (expiredOrders.length > 0) {
            this.logger.log(`Found ${expiredOrders.length} expired reservations. Cancelling...`);
            for (const order of expiredOrders) {
                await this.prisma.$transaction([
                    this.prisma.order.update({
                        where: { id: order.id },
                        data: {
                            status: OrderStatus.CANCELLED,
                            cancellationReason: 'Expiration automatique : le vendeur n\'a pas confirmé la commande sous 2h.',
                        },
                    }),
                    this.prisma.product.update({
                        where: { id: order.productId },
                        data: { status: ProductStatus.PUBLISHED },
                    }),
                ]);
            }
        }
    }

    // Run every hour to check for completed return windows
    @Cron('0 0 * * * *')
    async handleExpiredReturnWindows() {
        this.logger.debug('Checking for expired return windows...');

        const fortyEightHoursAgo = new Date();
        fortyEightHoursAgo.setHours(fortyEightHoursAgo.getHours() - 48);

        // Find orders that are in DELIVERED or RETURN_WINDOW_48H status
        // and were delivered more than 48 hours ago
        const completedOrders = await this.prisma.order.findMany({
            where: {
                status: {
                    in: [OrderStatus.DELIVERED, OrderStatus.RETURN_WINDOW_48H],
                },
                deliveredAt: {
                    lt: fortyEightHoursAgo,
                },
            },
        });

        if (completedOrders.length > 0) {
            this.logger.log(`Found ${completedOrders.length} orders with expired return windows. Completing...`);
            for (const order of completedOrders) {
                await this.prisma.order.update({
                    where: { id: order.id },
                    data: { status: OrderStatus.COMPLETED, completedAt: new Date() },
                });
            }
        }
    }
}
