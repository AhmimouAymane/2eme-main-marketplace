import {
    Controller,
    Get,
    Post,
    Param,
    UseGuards,
    Req,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { FavoritesService } from './favorites.service';
import { AuthGuard } from '@nestjs/passport';
import type { Request } from 'express';

@ApiTags('favorites')
@Controller('favorites')
@UseGuards(AuthGuard('jwt'))
@ApiBearerAuth()
export class FavoritesController {
    constructor(private readonly favoritesService: FavoritesService) { }

    @Post(':productId')
    @ApiOperation({ summary: 'Toggle product favorite status' })
    @ApiResponse({ status: 201, description: 'Favorite status toggled successfully' })
    toggleFavorite(@Param('productId') productId: string, @Req() req: Request) {
        const userId = (req.user as any).sub;
        return this.favoritesService.toggleFavorite(userId, productId);
    }

    @Get()
    @ApiOperation({ summary: 'Get all favorites for the current user' })
    @ApiResponse({ status: 200, description: 'Return all favorites' })
    getFavorites(@Req() req: Request) {
        const userId = (req.user as any).sub;
        return this.favoritesService.getFavorites(userId);
    }
}
