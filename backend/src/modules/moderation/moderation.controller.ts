import { Controller, Post, Get, Delete, Body, Param, UseGuards, Req } from '@nestjs/common';
import { ModerationService } from './moderation.service';
import { AuthGuard } from '@nestjs/passport';
import { ReportReason } from '@prisma/client';

@Controller('moderation')
@UseGuards(AuthGuard('jwt'))
export class ModerationController {
    constructor(private moderationService: ModerationService) { }

    @Post('report')
    async reportContent(
        @Req() req: any,
        @Body() data: {
            reason: ReportReason;
            description?: string;
            reportedUserId?: string;
            reportedProductId?: string;
            reportedCommentId?: string;
        },
    ) {
        return this.moderationService.reportContent(req.user.sub, data);
    }

    @Post('block/:userId')
    async blockUser(@Req() req: any, @Param('userId') blockedUserId: string) {
        return this.moderationService.blockUser(req.user.sub, blockedUserId);
    }

    @Delete('block/:userId')
    async unblockUser(@Req() req: any, @Param('userId') blockedUserId: string) {
        return this.moderationService.unblockUser(req.user.sub, blockedUserId);
    }

    @Get('blocks')
    async getBlockedUsers(@Req() req: any) {
        return this.moderationService.getBlockedUsers(req.user.sub);
    }
}
