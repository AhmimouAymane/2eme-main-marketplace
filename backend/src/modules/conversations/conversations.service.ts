import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Conversation, Message, NotificationType } from '@prisma/client';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class ConversationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) { }

  async findOrCreateConversation(productId: string, userId: string): Promise<Conversation> {
    // Récupérer le produit pour identifier le vendeur
    const product = await this.prisma.product.findUnique({
      where: { id: productId },
      select: { id: true, sellerId: true },
    });

    if (!product) {
      throw new NotFoundException('Product not found');
    }

    if (product.sellerId === userId) {
      throw new ForbiddenException('You cannot start a conversation with yourself');
    }

    const buyerId = userId;
    const sellerId = product.sellerId;

    const existing = await this.prisma.conversation.findFirst({
      where: {
        productId,
        buyerId,
        sellerId,
      },
    });

    if (existing) {
      return existing;
    }

    return this.prisma.conversation.create({
      data: {
        productId,
        buyerId,
        sellerId,
      },
    });
  }

  async findOrCreateOrderConversation(orderId: string, userId: string): Promise<Conversation> {
    // Récupérer la commande pour identifier les parties
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: { id: true, productId: true, buyerId: true, sellerId: true },
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    if (order.buyerId !== userId && order.sellerId !== userId) {
      throw new ForbiddenException('You are not part of this order');
    }

    const productId = order.productId;
    const buyerId = order.buyerId;
    const sellerId = order.sellerId;

    const existing = await this.prisma.conversation.findFirst({
      where: {
        productId,
        buyerId,
        sellerId,
      },
    });

    if (existing) {
      return existing;
    }

    return this.prisma.conversation.create({
      data: {
        productId,
        buyerId,
        sellerId,
      },
    });
  }

  async getUserConversations(userId: string) {
    return this.prisma.conversation.findMany({
      where: {
        OR: [
          { buyerId: userId, deletedByBuyer: false },
          { sellerId: userId, deletedBySeller: false },
        ],
      },
      include: {
        product: {
          include: { images: true },
        },
        buyer: {
          select: { id: true, firstName: true, lastName: true, avatarUrl: true },
        },
        seller: {
          select: { id: true, firstName: true, lastName: true, avatarUrl: true },
        },
        messages: {
          orderBy: { createdAt: 'asc' },
        },
      },
      orderBy: { lastMessageAt: 'desc' },
    });
  }

  async getConversation(id: string, userId: string) {
    const conversation = await this.prisma.conversation.findUnique({
      where: { id },
      include: {
        product: {
          include: { images: true },
        },
        buyer: {
          select: { id: true, firstName: true, lastName: true, avatarUrl: true },
        },
        seller: {
          select: { id: true, firstName: true, lastName: true, avatarUrl: true },
        },
      },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    if (conversation.buyerId !== userId && conversation.sellerId !== userId) {
      throw new ForbiddenException('You are not part of this conversation');
    }

    return conversation;
  }

  async getMessages(conversationId: string, userId: string): Promise<Message[]> {
    await this.getConversation(conversationId, userId);

    return this.prisma.message.findMany({
      where: { conversationId },
      orderBy: { createdAt: 'asc' },
    });
  }

  async createMessage(conversationId: string, senderId: string, content: string): Promise<any> {
    try {
      const conversation = await this.getConversation(conversationId, senderId);

      const message = await this.prisma.message.create({
        data: {
          conversationId: conversation.id,
          senderId,
          content,
        },
      });

      const isBuyerSender = conversation.buyerId === senderId;
      const recipientId = isBuyerSender ? conversation.sellerId : conversation.buyerId;

      await this.prisma.conversation.update({
        where: { id: conversation.id },
        data: {
          lastMessageAt: message.createdAt,
          // Unhide for recipient if they previously deleted/hid it
          ...(isBuyerSender
            ? { deletedBySeller: false }
            : { deletedByBuyer: false }),
        },
      });

      // Create notification for recipient
      const sender = isBuyerSender ? (conversation as any).buyer : (conversation as any).seller;
      const senderName = sender?.firstName || 'Un utilisateur';

      await this.notificationsService.create({
        userId: recipientId,
        title: `💬 Message de ${senderName}`,
        message: content.length > 50 ? `${content.substring(0, 50)}...` : content,
        type: NotificationType.MESSAGE_RECEIVED,
        data: {
          conversationId: conversation.id,
          senderId,
          screen: 'chat',
        },
      });

      return {
        ...message,
        senderName,
      };
    } catch (error) {
      console.error('Error creating message:', error);
      throw error;
    }
  }

  async markAsRead(conversationId: string, userId: string): Promise<void> {
    await this.getConversation(conversationId, userId);

    await this.prisma.message.updateMany({
      where: {
        conversationId,
        senderId: {
          not: userId,
        },
        isRead: false,
      },
      data: {
        isRead: true,
      },
    });

    // AUSSI : Marquer les notifications de type message comme lues pour cette conversation
    await this.prisma.notification.updateMany({
      where: {
        userId,
        type: NotificationType.MESSAGE_RECEIVED,
        isRead: false,
        data: {
          path: ['conversationId'],
          equals: conversationId,
        },
      },
      data: { isRead: true },
    });
  }

  async softDeleteConversation(id: string, userId: string): Promise<void> {
    const conversation = await this.getConversation(id, userId);

    const isBuyer = conversation.buyerId === userId;

    await this.prisma.conversation.update({
      where: { id },
      data: {
        [isBuyer ? 'deletedByBuyer' : 'deletedBySeller']: true,
      },
    });
  }
}
