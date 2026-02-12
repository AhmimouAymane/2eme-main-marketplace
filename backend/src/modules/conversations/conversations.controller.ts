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
  ) {}

  @Post('product/:productId')
  @ApiOperation({ summary: 'Create or get a conversation for a product' })
  createOrGetConversation(
    @Param('productId') productId: string,
    @GetCurrentUser('sub') userId: string,
  ) {
    return this.conversationsService.findOrCreateConversation(productId, userId);
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
      .then((message) => {
        // Diffuse globalement, le client filtrera par conversationId
        this.chatGateway.server.emit('new_message', message);
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
}

