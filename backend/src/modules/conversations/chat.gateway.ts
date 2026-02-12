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

  constructor(private readonly conversationsService: ConversationsService) {}

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

    // Diffuse à tous les clients connectés ; le client filtrera par conversationId
    this.server.emit('new_message', message);
  }
}

