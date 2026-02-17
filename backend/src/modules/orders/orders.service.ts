import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { UpdateOrderDto } from './dto/update-order.dto';
import { Order, OrderStatus, ProductStatus } from '@prisma/client';

@Injectable()
export class OrdersService {
    constructor(private prisma: PrismaService) { }

    async create(createOrderDto: CreateOrderDto, buyerId: string): Promise<Order> {
        const { productId, totalPrice, shippingAddress } = createOrderDto;

        // Check if product exists and is available
        const product = await this.prisma.product.findUnique({
            where: { id: productId },
        });

        if (!product) {
            throw new NotFoundException(`Product with ID ${productId} not found`);
        }

        if (product.status !== ProductStatus.FOR_SALE) {
            throw new ForbiddenException('Product is no longer for sale');
        }

        if (product.sellerId === buyerId) {
            throw new ForbiddenException('You cannot buy your own product');
        }

        // Create order and update product status in a transaction
        const [order] = await this.prisma.$transaction([
            this.prisma.order.create({
                data: {
                    productId,
                    buyerId,
                    sellerId: product.sellerId,
                    totalPrice,
                    shippingAddress,
                    status: OrderStatus.PENDING,
                },
                include: {
                    product: true,
                    buyer: {
                        select: { id: true, firstName: true, lastName: true, email: true, addresses: true },
                    },
                    seller: {
                        select: { id: true, firstName: true, lastName: true, email: true, addresses: true },
                    },
                },
            }),
            this.prisma.product.update({
                where: { id: productId },
                data: { status: ProductStatus.RESERVED },
            }),
        ]);

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
        // Here we allow both for simplicity, but usually status flow is controlled
        if (order.sellerId !== userId && order.buyerId !== userId) {
            throw new ForbiddenException('You do not have permission to update this order');
        }

        // Only seller can confirm and provide pickup address
        if (updateOrderDto.status === OrderStatus.CONFIRMED && order.sellerId !== userId) {
            throw new ForbiddenException('Only the seller can confirm the order');
        }

        if (updateOrderDto.pickupAddress && order.sellerId !== userId) {
            throw new ForbiddenException('Only the seller can provide a pickup address');
        }

        const updatedOrder = await this.prisma.order.update({
            where: { id },
            data: {
                ...updateOrderDto,
                deliveredAt: updateOrderDto.status === OrderStatus.DELIVERED ? new Date() : undefined,
            },
        });

        // If order is delivered, mark product as SOLD
        if (updateOrderDto.status === OrderStatus.DELIVERED) {
            await this.prisma.product.update({
                where: { id: order.productId },
                data: { status: ProductStatus.SOLD },
            });
        }

        // If order is cancelled, mark product as FOR_SALE again
        if (updateOrderDto.status === OrderStatus.CANCELLED) {
            await this.prisma.product.update({
                where: { id: order.productId },
                data: { status: ProductStatus.FOR_SALE },
            });
        }

        return updatedOrder;
    }
}
