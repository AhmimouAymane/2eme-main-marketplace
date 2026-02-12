import { Controller, Get, Patch, Body, Param, UseGuards, NotFoundException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { UsersService } from './users.service';
import { GetCurrentUser } from '../../common/decorators/get-current-user.decorator';
import { UpdateUserDto } from './dto/update-user.dto';

@ApiTags('users')
@Controller('users')
export class UsersController {
    constructor(private usersService: UsersService) { }

    @Get('me')
    @UseGuards(AuthGuard('jwt'))
    @ApiBearerAuth()
    @ApiOperation({ summary: 'Get current user profile' })
    getMe(@GetCurrentUser('sub') userId: string) {
        return this.usersService.findOne(userId);
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

    @Get(':id')
    @ApiOperation({ summary: 'Get a user profile by ID (public)' })
    async getOne(@Param('id') id: string) {
        const user = await this.usersService.findOne(id, true);
        if (!user) {
            throw new NotFoundException('User not found');
        }
        // Don't expose password
        const { password, ...result } = user;
        return result;
    }
}
