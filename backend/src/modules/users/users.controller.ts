import { Controller, Get, Post, Patch, Delete, Body, Param, UseGuards, NotFoundException, Query, Res, Req } from '@nestjs/common';
import type { Response, Request } from 'express';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { UsersService } from './users.service';
import { GetCurrentUser } from '../../common/decorators/get-current-user.decorator';
import { UpdateUserDto } from './dto/update-user.dto';
import { OptionalAuthGuard } from '../../common/guards/optional-auth.guard';

@ApiTags('users')
@Controller('users')
export class UsersController {
    constructor(private usersService: UsersService) { }

    @Get()
    @ApiOperation({ summary: 'List all users (Admin only)' })
    async findAll(@Res() res: Response, @Query() query: { _start?: number, _end?: number }) {
        const { data, total } = await this.usersService.findAll(query);
        res.setHeader('X-Total-Count', total);
        res.setHeader('Access-Control-Expose-Headers', 'X-Total-Count');
        return res.json(data);
    }

    @Get('search')
    @ApiOperation({ summary: 'Search users by name' })
    async search(@Query('q') query: string) {
        return this.usersService.search(query);
    }

    @Get('me')
    @UseGuards(AuthGuard('jwt'))
    @ApiBearerAuth()
    @ApiOperation({ summary: 'Get current user profile' })
    async getMe(@GetCurrentUser('sub') userId: string) {
        const user = await this.usersService.findOne(userId, true, false, userId);
        if (!user) {
            throw new NotFoundException('User profile not found in database');
        }
        return user;
    }

    @Patch('me')
    @UseGuards(AuthGuard('jwt'))
    @ApiBearerAuth()
    @ApiOperation({ summary: 'Update current user profile' })
    updateMe(
        @GetCurrentUser('sub') userId: string,
        @Body() updateUserDto: UpdateUserDto,
    ) {
        return this.usersService.update(userId, updateUserDto);
    }

    @Delete('me')
    @UseGuards(AuthGuard('jwt'))
    @ApiBearerAuth()
    @ApiOperation({ summary: 'Delete current user account (DB + Firebase)' })
    deleteMe(@GetCurrentUser('sub') userId: string) {
        return this.usersService.remove(userId);
    }

    @Get(':id')
    @UseGuards(OptionalAuthGuard)
    @ApiOperation({ summary: 'Get a user profile by ID (public)' })
    async getOne(@Param('id') id: string, @Req() req: Request) {
        const viewerId = (req.user as any)?.sub;
        const user = await this.usersService.findOne(id, true, true, viewerId);
        if (!user) {
            throw new NotFoundException('User not found');
        }
        return user;
    }

    @Post(':id/reviews')
    @UseGuards(AuthGuard('jwt'))
    @ApiBearerAuth()
    @ApiOperation({ summary: 'Rate a user (seller)' })
    async rateUser(
        @GetCurrentUser('sub') reviewerId: string,
        @Param('id') targetUserId: string,
        @Body('rating') rating: number,
        @Body('comment') comment?: string,
    ) {
        return this.usersService.rateUser(reviewerId, targetUserId, rating, comment);
    }
}
