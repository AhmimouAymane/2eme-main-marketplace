import { Injectable, NotFoundException, ForbiddenException, BadRequestException, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { UpdateOrderDto } from './dto/update-order.dto';
import { Order, OrderStatus, ProductStatus, NotificationType } from '@prisma/client';

import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class OrdersService {
    private readonly logger = new Logger(OrdersService.name);

    constructor(
        private prisma: PrismaService,
        private notificationsService: NotificationsService,
    ) { }

    async create(createOrderDto: CreateOrderDto, buyerId: string): Promise<Order> {
        const { productId, totalPrice, serviceFee, shippingFee, shippingAddress, status } = createOrderDto;

        // Check if product exists and is available
        const product = await this.prisma.product.findUnique({
            where: { id: productId },
        });

        if (!product) {
            throw new NotFoundException(`Product with ID ${productId} not found`);
        }

        // Only allow purchase or offer if product is PUBLISHED
        if (product.status !== ProductStatus.PUBLISHED) {
            throw new ForbiddenException('Product is no longer available');
        }

        if (product.sellerId === buyerId) {
            throw new ForbiddenException('You cannot buy your own product');
        }

        // Fetch current system settings for fees
        const settings = await this.prisma.systemSettings.findUnique({
            where: { id: 'default' },
        });

        const systemServiceFeePercentage = settings?.serviceFeePercentage || 5.0;
        const systemShippingFee = settings?.shippingFee || 25.0;

        // Recalculate fees for security if not provided or to ensure they match backend logic
        // We round up the service fee as in the frontend
        const calculatedServiceFee = Math.ceil(product.price * (systemServiceFeePercentage / 100));

        const finalServiceFee = serviceFee !== undefined ? serviceFee : calculatedServiceFee;
        const finalShippingFee = shippingFee !== undefined ? shippingFee : systemShippingFee;
        const finalTotalPrice = product.price + finalServiceFee + finalShippingFee;

        // Default status for "Buy Now" is AWAITING_SELLER_CONFIRMATION
        // If it's an offer, it would be OFFER_MADE (logic can be expanded)
        const orderStatus = status || OrderStatus.AWAITING_SELLER_CONFIRMATION;

        // Prepare transaction steps
        const transactionSteps: any[] = [
            this.prisma.order.create({
                data: {
                    productId,
                    buyerId,
                    sellerId: product.sellerId,
                    totalPrice: finalTotalPrice,
                    serviceFee: finalServiceFee,
                    shippingFee: finalShippingFee,
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

        // Reserve the product for all orders except specific offer types if needed
        // For now, "Buy Now" always reserves.
        if (orderStatus !== OrderStatus.OFFER_MADE) {
            transactionSteps.push(
                this.prisma.product.update({
                    where: { id: productId },
                    data: { status: ProductStatus.RESERVED },
                }),
            );
        }

        const [order] = await this.prisma.$transaction(transactionSteps);

        // Create notification for seller
        const isOffer = orderStatus === OrderStatus.OFFER_MADE;
        await this.notificationsService.create({
            userId: product.sellerId,
            title: isOffer ? '🤝 Nouvelle offre reçue !' : '🛒 Nouvelle commande reçue !',
            message: isOffer
                ? `${order.buyer.firstName} propose ${totalPrice} MAD pour "${product.title}".`
                : `Vous avez reçu une nouvelle commande pour "${product.title}".`,
            type: NotificationType.NEW_ORDER_RECEIVED,
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
                userReviews: true,
            },
            orderBy: { createdAt: 'desc' },
        });
    }

    async findAllForAdmin(query: { _start?: number; _end?: number; _sort?: string; _order?: string }) {
        const take = (query._end !== undefined && query._start !== undefined)
            ? Number(query._end) - Number(query._start)
            : undefined;
        const skip = query._start ? Number(query._start) : undefined;
        const orderField = query._sort || 'createdAt';
        const orderDir = ((query._order || 'desc').toLowerCase()) as 'asc' | 'desc';
        const orderBy = { [orderField]: orderDir };

        const [data, total] = await this.prisma.$transaction([
            this.prisma.order.findMany({
                include: {
                    product: { include: { images: true } },
                    buyer: { select: { id: true, firstName: true, lastName: true, email: true } },
                    seller: { select: { id: true, firstName: true, lastName: true, email: true } },
                },
                orderBy,
                skip,
                take,
            }),
            this.prisma.order.count(),
        ]);

        return { data, total };
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
                userReviews: true,
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
        this.logger.log(`Updating order ${id} for user ${userId}. New status: ${updateOrderDto.status}`);
        const order = await this.findOne(id, userId);

        // Permissions and Validations
        if (order.sellerId !== userId && order.buyerId !== userId) {
            throw new ForbiddenException('You do not have permission to update this order');
        }

        const { status } = updateOrderDto;

        // Status-specific logic and milestone timestamps
        const additionalData: any = {};

        if (status) {
            switch (status) {
                case OrderStatus.CONFIRMED:
                    if (order.sellerId !== userId) throw new ForbiddenException('Only the seller can confirm the order');
                    if (!updateOrderDto.pickupAddress) throw new BadRequestException('A pickup address is required');
                    additionalData.confirmedAt = new Date();
                    break;

                case OrderStatus.SHIPPED:
                    if (order.sellerId !== userId) throw new ForbiddenException('Only the seller can mark as shipped');
                    additionalData.shippedAt = new Date();
                    break;

                case OrderStatus.DELIVERED:
                    // When delivered, we immediately enter the 48h return window
                    updateOrderDto.status = OrderStatus.RETURN_WINDOW_48H;
                    additionalData.deliveredAt = new Date();
                    break;

                case OrderStatus.RETURN_REQUESTED:
                    if (order.buyerId !== userId) throw new ForbiddenException('Only the buyer can request a return');
                    if (!order.deliveredAt) throw new BadRequestException('Order must be delivered first');

                    const deliveredDate = new Date(order.deliveredAt);
                    const now = new Date();
                    const diffHours = (now.getTime() - deliveredDate.getTime()) / (1000 * 60 * 60);
                    if (diffHours > 48) throw new ForbiddenException('Return window (48h) has passed');

                    if (!updateOrderDto.returnReason) throw new BadRequestException('A reason is required for returns');
                    additionalData.returnRequestedAt = new Date();
                    break;

                case OrderStatus.RETURNED:
                    if (order.sellerId !== userId) throw new ForbiddenException('Only the seller can confirm the return receipt');
                    if (order.status !== OrderStatus.RETURN_REQUESTED) throw new BadRequestException('Can only confirm return receipt for requested returns');
                    additionalData.returnedAt = new Date();
                    break;

                case OrderStatus.CANCELLED:
                    // Accept any reason for cancellation
                    if (!updateOrderDto.cancellationReason && !updateOrderDto.rejectionReason && !updateOrderDto.returnReason) {
                        throw new BadRequestException('A reason is required for cancellation or rejection');
                    }
                    // For robustness, ensure we set something if BOTH are provided (though DTO allows it)
                    break;

                case OrderStatus.COMPLETED:
                    additionalData.completedAt = new Date();
                    break;
            }
        }

        const updatedOrder = await this.prisma.$transaction(async (tx) => {
            const result = await tx.order.update({
                where: { id },
                data: {
                    status: updateOrderDto.status,
                    shippingAddress: updateOrderDto.shippingAddress,
                    pickupAddress: updateOrderDto.pickupAddress,
                    rejectionReason: updateOrderDto.rejectionReason,
                    cancellationReason: updateOrderDto.cancellationReason,
                    returnReason: updateOrderDto.returnReason,
                    ...additionalData,
                },
                include: { product: true },
            });

            // Synchronize Product Status
            if (status) {
                let targetProductStatus: ProductStatus | null = null;

                switch (status) {
                    case OrderStatus.CONFIRMED:
                    case OrderStatus.SHIPPED:
                    case OrderStatus.AWAITING_SELLER_CONFIRMATION:
                        targetProductStatus = ProductStatus.CONFIRMED;
                        break;

                    case OrderStatus.DELIVERED:
                    case OrderStatus.RETURN_WINDOW_48H:
                    case OrderStatus.COMPLETED:
                        targetProductStatus = ProductStatus.SOLD;
                        break;

                    case OrderStatus.CANCELLED:
                    case OrderStatus.RETURNED:
                        targetProductStatus = ProductStatus.PUBLISHED;
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

        this.logger.log(`Order ${id} successfully updated to status ${status}`);

        // Notifications
        if (status) {
            const isSeller = order.sellerId === userId;
            const recipientId = isSeller ? order.buyerId : order.sellerId;

            const statusConfig: Record<string, { title: string, label: string, type: NotificationType }> = {
                OFFER_MADE: { title: '🤝 Nouvelle offre', label: 'a fait une offre', type: NotificationType.NEW_ORDER_RECEIVED },
                AWAITING_SELLER_CONFIRMATION: { title: '🛒 Commande reçue', label: 'a passé commande', type: NotificationType.NEW_ORDER_RECEIVED },
                CONFIRMED: { title: '💰 Commande confirmée', label: 'est confirmée', type: NotificationType.ORDER_CONFIRMED },
                SHIPPED: { title: '📦 En route !', label: 'a été expédiée', type: NotificationType.ORDER_SHIPPED },
                DELIVERED: { title: '✅ Livré', label: 'est livrée', type: NotificationType.ORDER_DELIVERED },
                RETURN_REQUESTED: { title: '🔄 Retour demandé', label: 'fait l\'objet d\'une demande de retour', type: NotificationType.SECURITY_ALERT },
                RETURNED: { title: '🔙 Retourné', label: 'est retournée au vendeur', type: NotificationType.SECURITY_ALERT },
                CANCELLED: { title: '❌ Annulé', label: 'est annulée', type: NotificationType.SECURITY_ALERT },
                COMPLETED: { title: '✨ Terminé', label: 'est terminée', type: NotificationType.PAYMENT_RECEIVED },
            };

            const config = statusConfig[status];
            if (config) {
                let reason = updateOrderDto.rejectionReason || updateOrderDto.cancellationReason || updateOrderDto.returnReason;
                await this.notificationsService.create({
                    userId: recipientId,
                    title: config.title,
                    message: reason
                        ? `Votre commande pour "${(order as any).product.title}" ${config.label} : ${reason}`
                        : `Votre commande pour "${(order as any).product.title}" ${config.label}.`,
                    type: config.type,
                    data: { orderId: order.id, screen: 'order_detail' },
                });
            }
        }

        return updatedOrder;
    }
}
