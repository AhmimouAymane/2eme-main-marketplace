import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { UpdateOrderDto } from './dto/update-order.dto';
import { Order, OrderStatus, ProductStatus, NotificationType } from '@prisma/client';

import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class OrdersService {
    constructor(
        private prisma: PrismaService,
        private notificationsService: NotificationsService,
    ) { }

    async create(createOrderDto: CreateOrderDto, buyerId: string): Promise<Order> {
        const { productId, totalPrice, shippingAddress, status } = createOrderDto;

        // Check if product exists and is available
        const product = await this.prisma.product.findUnique({
            where: { id: productId },
        });

        if (!product) {
            throw new NotFoundException(`Product with ID ${productId} not found`);
        }

        // Only allow purchase or offer if product is FOR_SALE
        if (product.status !== ProductStatus.FOR_SALE) {
            throw new ForbiddenException('Product is no longer for sale');
        }

        if (product.sellerId === buyerId) {
            throw new ForbiddenException('You cannot buy your own product');
        }

        const orderStatus = status || OrderStatus.PENDING;

        // Prepare transaction steps
        const transactionSteps: any[] = [
            this.prisma.order.create({
                data: {
                    productId,
                    buyerId,
                    sellerId: product.sellerId,
                    totalPrice,
                    shippingAddress,
                    status: orderStatus,
                },
                include: {
                    product: true,
                    buyer: {
                        select: { id: true, firstName: true, lastName: true, email: true },
                    },
                    seller: {
                        select: { id: true, firstName: true, lastName: true, email: true },
                    },
                },
            }),
        ];

        // Only reserve the product if it's a direct purchase (PENDING), not an offer
        if (orderStatus !== OrderStatus.OFFER_PENDING) {
            transactionSteps.push(
                this.prisma.product.update({
                    where: { id: productId },
                    data: { status: ProductStatus.RESERVED },
                }),
            );
        }

        const [order] = await this.prisma.$transaction(transactionSteps);

        // Create notification for seller
        const isOffer = orderStatus === (OrderStatus as any).OFFER_PENDING;
        await this.notificationsService.create({
            userId: product.sellerId,
            title: isOffer ? '🤝 Nouvelle offre reçue !' : '🛒 Nouvelle commande reçue !',
            message: isOffer
                ? `${order.buyer.firstName} propose ${totalPrice}€ pour "${product.title}".`
                : `Vous avez reçu une nouvelle commande pour "${product.title}".`,
            type: isOffer ? NotificationType.NEW_ORDER_RECEIVED : NotificationType.NEW_ORDER_RECEIVED, // Reuse for now or refine if needed
            data: { orderId: order.id, screen: 'order_detail' },
        });

        return order;
    }

    async findAll(userId: string, role: 'buyer' | 'seller'): Promise<Order[]> {
        return this.prisma.order.findMany({
            where: role === 'buyer' ? { buyerId: userId } : { sellerId: userId },
            include: {
                product: {
                    include: { images: true },
                },
                buyer: {
                    select: { id: true, firstName: true, lastName: true },
                },
                seller: {
                    select: { id: true, firstName: true, lastName: true },
                },
            },
            orderBy: { createdAt: 'desc' },
        });
    }

    async findOne(id: string, userId: string): Promise<Order> {
        const order = await this.prisma.order.findUnique({
            where: { id },
            include: {
                product: {
                    include: { images: true },
                },
                buyer: {
                    select: { id: true, firstName: true, lastName: true, email: true, addresses: true },
                },
                seller: {
                    select: { id: true, firstName: true, lastName: true, email: true, addresses: true },
                },
            },
        });

        if (!order) {
            throw new NotFoundException(`Order with ID ${id} not found`);
        }

        if (order.buyerId !== userId && order.sellerId !== userId) {
            throw new ForbiddenException('You do not have permission to view this order');
        }

        return order;
    }

    async update(id: string, updateOrderDto: UpdateOrderDto, userId: string): Promise<Order> {
        const order = await this.findOne(id, userId);

        // Only seller or admin can update status (in a real app)
        if (order.sellerId !== userId && order.buyerId !== userId) {
            throw new ForbiddenException('You do not have permission to update this order');
        }

        // Status-specific permissions
        if (updateOrderDto.status === OrderStatus.CONFIRMED && order.sellerId !== userId) {
            throw new ForbiddenException('Only the seller can confirm the order');
        }

        if (updateOrderDto.pickupAddress && order.sellerId !== userId) {
            throw new ForbiddenException('Only the seller can provide a pickup address');
        }

        // 48h Return Window check
        if (updateOrderDto.status === (OrderStatus as any).RETURN_REQUESTED) {
            if (order.buyerId !== userId) {
                throw new ForbiddenException('Only the buyer can request a return');
            }
            if (!order.deliveredAt) {
                throw new ForbiddenException('Order must be delivered before requesting a return');
            }
            const deliveredDate = new Date(order.deliveredAt);
            const now = new Date();
            const diffHours = (now.getTime() - deliveredDate.getTime()) / (1000 * 60 * 60);
            if (diffHours > 48) {
                throw new ForbiddenException('Return window (48h) has passed');
            }
        }

        // TRANSACTION: Update order and product status atomically
        const updatedOrder = await this.prisma.$transaction(async (tx) => {
            const result = await tx.order.update({
                where: { id },
                data: {
                    ...updateOrderDto,
                    deliveredAt: updateOrderDto.status === OrderStatus.DELIVERED ? new Date() : undefined,
                },
                include: { product: true },
            });

            // Handle Product Status based on Order Status
            if (updateOrderDto.status) {
                let targetProductStatus: ProductStatus | null = null;

                switch (updateOrderDto.status) {
                    case OrderStatus.DELIVERED:
                        targetProductStatus = ProductStatus.SOLD;
                        break;

                    case OrderStatus.CANCELLED:
                    case (OrderStatus as any).OFFER_REJECTED:
                        targetProductStatus = ProductStatus.FOR_SALE;
                        break;

                    case OrderStatus.CONFIRMED:
                    case OrderStatus.SHIPPED:
                    case OrderStatus.PENDING:
                        targetProductStatus = ProductStatus.RESERVED;
                        break;
                }

                if (targetProductStatus) {
                    await tx.product.update({
                        where: { id: order.productId },
                        data: { status: targetProductStatus },
                    });
                }
            }

            return result;
        });

        // Notify relevant user about status change (outside transaction to avoid delays)
        if (updateOrderDto.status) {
            const isSeller = order.sellerId === userId;
            const recipientId = isSeller ? order.buyerId : order.sellerId;

            const statusLabels: Record<string, string> = {
                OFFER_PENDING: 'prix proposé',
                OFFER_REJECTED: 'offre refusée',
                PENDING: 'en attente',
                CONFIRMED: 'confirmée',
                SHIPPED: 'expédiée',
                DELIVERED: 'livrée',
                CANCELLED: 'annulée',
                RETURN_REQUESTED: 'demande de retour effectuée',
            };

            const notificationMap: Record<string, { title: string, type: NotificationType }> = {
                OFFER_PENDING: { title: 'Offre reçue', type: NotificationType.NEW_ORDER_RECEIVED },
                OFFER_REJECTED: { title: '❌ Offre refusée', type: NotificationType.SECURITY_ALERT },
                PENDING: { title: 'Commande en attente', type: NotificationType.NEW_ORDER_RECEIVED },
                CONFIRMED: { title: '💰 Commande confirmée', type: NotificationType.ORDER_CONFIRMED },
                SHIPPED: { title: '📦 Commande expédiée', type: NotificationType.ORDER_SHIPPED },
                DELIVERED: { title: '✅ Commande livrée', type: NotificationType.ORDER_DELIVERED },
                CANCELLED: { title: '❌ Commande annulée', type: NotificationType.SECURITY_ALERT },
                RETURN_REQUESTED: { title: '🔄 Demande de retour', type: NotificationType.SECURITY_ALERT },
            };

            const config = notificationMap[updateOrderDto.status];

            if (config) {
                await this.notificationsService.create({
                    userId: recipientId,
                    title: config.title,
                    message: updateOrderDto.rejectionReason
                        ? `Votre commande pour "${(order as any).product.title}" est ${statusLabels[updateOrderDto.status]} : ${updateOrderDto.rejectionReason}`
                        : `Votre commande pour "${(order as any).product.title}" est désormais ${statusLabels[updateOrderDto.status]}.`,
                    type: config.type,
                    data: { orderId: order.id, screen: 'order_detail' },
                });
            }

            // If delivered, also send rating request
            if (updateOrderDto.status === OrderStatus.DELIVERED) {
                await this.notificationsService.create({
                    userId: order.buyerId,
                    title: '⭐ Évaluez votre achat !',
                    message: `Comment s'est passée votre commande pour "${(order as any).product.title}" ? Laissez une évaluation !`,
                    type: NotificationType.RATING_REQUEST,
                    data: { productId: order.productId, screen: 'product_detail' },
                });

                await this.notificationsService.create({
                    userId: order.sellerId,
                    title: '📤 Paiement reçu !',
                    message: `Le paiement pour votre vente "${(order as any).product.title}" a été crédité sur votre compte Clovi.`,
                    type: NotificationType.PAYMENT_RECEIVED,
                    data: { orderId: order.id, screen: 'order_detail' },
                });
            }
        }

        return updatedOrder;
    }
}
