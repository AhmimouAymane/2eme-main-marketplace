import { Controller, Post, Get, Body, Param, UseGuards, Req } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { UserReviewsService } from './user-reviews.service';
import { CreateUserReviewDto } from './dto/create-user-review.dto';

@ApiTags('user-reviews')
@Controller('user-reviews')
export class UserReviewsController {
    constructor(private readonly userReviewsService: UserReviewsService) { }

    @Post()
    @UseGuards(AuthGuard('jwt'))
    @ApiBearerAuth()
    @ApiOperation({ summary: 'Submit a review for a completed order' })
    @ApiResponse({ status: 201, description: 'Review successfully created' })
    create(@Req() req: any, @Body() dto: CreateUserReviewDto) {
        return this.userReviewsService.create(req.user.sub, dto);
    }

    @Get('user/:id')
    @ApiOperation({ summary: 'Get all reviews for a user' })
    findAllForUser(@Param('id') id: string) {
        return this.userReviewsService.getReviewsForUser(id);
    }

    @Get('top-sellers')
    @ApiOperation({ summary: 'Get top rated sellers' })
    getTopSellers() {
        return this.userReviewsService.getTopSellers();
    }

    @Get('order/:orderId/mine')
    @UseGuards(AuthGuard('jwt'))
    @ApiBearerAuth()
    @ApiOperation({ summary: 'Check if current user has already rated an order' })
    getMyReviewForOrder(@Req() req: any, @Param('orderId') orderId: string) {
        return this.userReviewsService.getReviewForOrder(orderId, req.user.sub);
    }
}
