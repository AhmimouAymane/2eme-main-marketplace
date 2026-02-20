import { Controller, Get, Patch, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { NotificationsService } from './notifications.service';
import { GetCurrentUser } from '../../common/decorators/get-current-user.decorator';

@ApiTags('notifications')
@Controller('notifications')
@UseGuards(AuthGuard('jwt'))
@ApiBearerAuth()
export class NotificationsController {
    constructor(private readonly notificationsService: NotificationsService) { }

    @Get()
    @ApiOperation({ summary: 'Get all notifications for the current user' })
    findAll(@GetCurrentUser('sub') userId: string) {
        return this.notificationsService.findAll(userId);
    }

    @Get('unread-count')
    @ApiOperation({ summary: 'Get unread notifications count' })
    getUnreadCount(@GetCurrentUser('sub') userId: string) {
        return this.notificationsService.getUnreadCount(userId);
    }

    @Patch(':id/read')
    @ApiOperation({ summary: 'Mark a notification as read' })
    markAsRead(
        @Param('id') id: string,
        @GetCurrentUser('sub') userId: string,
    ) {
        return this.notificationsService.markAsRead(id, userId);
    }

    @Patch('read-all')
    @ApiOperation({ summary: 'Mark all notifications as read' })
    markAllAsRead(@GetCurrentUser('sub') userId: string) {
        return this.notificationsService.markAllAsRead(userId);
    }
}
