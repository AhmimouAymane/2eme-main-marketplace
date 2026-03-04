import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { OrderStatus } from '@prisma/client';

@Injectable()
export class WalletService {
    constructor(private prisma: PrismaService) { }

    async getBalance(userId: string) {
        const orders = await this.prisma.order.findMany({
            where: {
                sellerId: userId,
                status: OrderStatus.COMPLETED,
            },
            select: {
                totalPrice: true,
                serviceFee: true,
            },
        });

        const balance = orders.reduce((acc, order) => {
            // Balance is the total price the buyer paid minus the service fee
            // (Shipping fee is typically handled separately or included depending on the carrier model, 
            // but here we focus on the product payout)
            return acc + (order.totalPrice - order.serviceFee);
        }, 0);

        return {
            balance,
            orderCount: orders.length,
        };
    }

    async getTransactions(userId: string) {
        return this.prisma.order.findMany({
            where: {
                sellerId: userId,
                status: OrderStatus.COMPLETED,
            },
            include: {
                product: {
                    select: {
                        title: true,
                        images: { take: 1 },
                    },
                },
            },
            orderBy: { completedAt: 'desc' },
        });
    }
}
