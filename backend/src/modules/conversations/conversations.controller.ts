import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { ConversationsService } from './conversations.service';
import { ChatGateway } from './chat.gateway';
import { GetCurrentUser } from '../../common/decorators/get-current-user.decorator';
import { IsNotEmpty, IsString } from 'class-validator';

class CreateMessageDto {
  @IsString()
  @IsNotEmpty()
  content: string;
}

@ApiTags('conversations')
@Controller('conversations')
@UseGuards(AuthGuard('jwt'))
@ApiBearerAuth()
export class ConversationsController {
  constructor(
    private readonly conversationsService: ConversationsService,
    private readonly chatGateway: ChatGateway,
  ) { }

  @Post('product/:productId')
  @ApiOperation({ summary: 'Create or get a conversation for a product' })
  createOrGetConversation(
    @Param('productId') productId: string,
    @GetCurrentUser('sub') userId: string,
  ) {
    return this.conversationsService.findOrCreateConversation(productId, userId);
  }

  @Post('order/:orderId')
  @ApiOperation({ summary: 'Create or get a conversation for an order' })
  createOrGetOrderConversation(
    @Param('orderId') orderId: string,
    @GetCurrentUser('sub') userId: string,
  ) {
    return this.conversationsService.findOrCreateOrderConversation(orderId, userId);
  }

  @Get()
  @ApiOperation({ summary: 'Get all conversations for current user' })
  getUserConversations(@GetCurrentUser('sub') userId: string) {
    return this.conversationsService.getUserConversations(userId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a single conversation by id' })
  getConversation(
    @Param('id') id: string,
    @GetCurrentUser('sub') userId: string,
  ) {
    return this.conversationsService.getConversation(id, userId);
  }

  @Get(':id/messages')
  @ApiOperation({ summary: 'Get messages for a conversation' })
  getMessages(
    @Param('id') id: string,
    @GetCurrentUser('sub') userId: string,
  ) {
    return this.conversationsService.getMessages(id, userId);
  }

  @Post(':id/messages')
  @ApiOperation({ summary: 'Send a message in a conversation' })
  sendMessage(
    @Param('id') id: string,
    @GetCurrentUser('sub') userId: string,
    @Body() body: CreateMessageDto,
  ) {
    return this.conversationsService
      .createMessage(id, userId, body.content)
      .then(async (message) => {
        if (this.chatGateway?.server) {
          const conversation = await this.conversationsService.getConversation(id, userId);
          const recipientId = conversation.buyerId === userId ? conversation.sellerId : conversation.buyerId;
          
          console.log(`DEBUG: [SOCKET] New message in ${id}. Notifying recipient user_${recipientId}`);
          
          // En émettant vers un tableau de rooms, Socket.IO se charge automatiquement
          // de dé-dupliquer l'événement pour un client qui serait dans les deux rooms.
          this.chatGateway.server.to([id, `user_${recipientId}`]).emit('new_message', message);
        }
        return message;
      });
  }

  @Post(':id/read')
  @ApiOperation({ summary: 'Mark messages as read in a conversation' })
  markAsRead(
    @Param('id') id: string,
    @GetCurrentUser('sub') userId: string,
  ) {
    return this.conversationsService.markAsRead(id, userId);
  }

  @Post(':id/delete')
  @ApiOperation({ summary: 'Soft delete/hide a conversation for the current user' })
  softDelete(
    @Param('id') id: string,
    @GetCurrentUser('sub') userId: string,
  ) {
    return this.conversationsService.softDeleteConversation(id, userId);
  }
}

