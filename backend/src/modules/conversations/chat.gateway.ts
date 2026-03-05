import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { UseGuards } from '@nestjs/common';
import { Server, Socket } from 'socket.io';
import { ConversationsService } from './conversations.service';
import { AuthGuard } from '@nestjs/passport';

interface SendMessagePayload {
  conversationId: string;
  content: string;
}

@WebSocketGateway({
  namespace: '/chat',
  cors: {
    origin: '*',
  },
})
export class ChatGateway {
  @WebSocketServer()
  server: Server;

  constructor(private readonly conversationsService: ConversationsService) { }

  async handleConnection(client: Socket) {
    // Le token est passé dans l'objet 'auth'
    const token = client.handshake.auth?.token;
    if (token) {
      try {
        // Idéalement, on décoderait le JWT ici pour avoir l'ID utilisateur
      } catch (err) {
      }
    }
  }

  @SubscribeMessage('identify')
  async handleIdentify(
    @MessageBody() data: { userId: string },
    @ConnectedSocket() client: Socket,
  ) {
    if (data.userId) {
      client.join(`user_${data.userId}`);
    }
  }

  @SubscribeMessage('join_conversation')
  async handleJoinConversation(
    @MessageBody() data: { conversationId: string },
    @ConnectedSocket() client: Socket,
  ) {
    client.join(data.conversationId);
  }

  @UseGuards(AuthGuard('jwt'))
  @SubscribeMessage('send_message')
  async handleSendMessage(
    @MessageBody() payload: SendMessagePayload,
    @ConnectedSocket() client: Socket & { user?: any },
  ) {
    const userId = (client as any).user?.sub;
    if (!userId) {
      return;
    }

    const message = await this.conversationsService.createMessage(
      payload.conversationId,
      userId,
      payload.content,
    );

    // 1. Envoie aux participants ACTIFS dans la conversation (ceux sur l'écran de chat)
    this.server.to(payload.conversationId).emit('new_message', message);

    // 2. Envoie au destinataire spécifique dans sa "personal room" 
    // pour déclencher la notification SnackBar même s'il n'est pas dans le chat
    const conversation = await this.conversationsService.getConversation(payload.conversationId, userId);
    const recipientId = conversation.buyerId === userId ? conversation.sellerId : conversation.buyerId;

    this.server.to(`user_${recipientId}`).emit('new_message', message);
  }
}

