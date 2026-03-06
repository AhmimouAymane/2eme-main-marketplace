import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { ConversationsService } from './conversations.service';
import { ConversationsController } from './conversations.controller';
import { ChatGateway } from './chat.gateway';
import { NotificationsModule } from '../notifications/notifications.module';
import { ModerationModule } from '../moderation/moderation.module';

@Module({
  imports: [PrismaModule, NotificationsModule, ModerationModule],
  controllers: [ConversationsController],
  providers: [ConversationsService, ChatGateway],
})
export class ConversationsModule { }

