import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Conversation, Message } from '@prisma/client';

@Injectable()
export class ConversationsService {
  constructor(private readonly prisma: PrismaService) {}

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

  async getUserConversations(userId: string) {
    return this.prisma.conversation.findMany({
      where: {
        OR: [{ buyerId: userId }, { sellerId: userId }],
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

  async createMessage(conversationId: string, senderId: string, content: string): Promise<Message> {
    const conversation = await this.getConversation(conversationId, senderId);

    const message = await this.prisma.message.create({
      data: {
        conversationId: conversation.id,
        senderId,
        content,
      },
    });

    await this.prisma.conversation.update({
      where: { id: conversation.id },
      data: {
        lastMessageAt: message.createdAt,
      },
    });

    return message;
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
  }
}

