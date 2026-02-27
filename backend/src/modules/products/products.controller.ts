import {
    Controller,
    Get,
    Post,
    Body,
    Patch,
    Param,
    Delete,
    UseGuards,
    Query,
    Req,
    Res,
} from '@nestjs/common';
import type { Response } from 'express';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { ProductsService, ProductQuery } from './products.service';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { AuthGuard } from '@nestjs/passport';
import { GetCurrentUser } from '../../common/decorators/get-current-user.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role, Category, ProductCondition, ProductStatus } from '@prisma/client';
import { OptionalAuthGuard } from '../../common/guards/optional-auth.guard';
import type { Request } from 'express';

@ApiTags('products')
@Controller('products')
export class ProductsController {
    constructor(private readonly productsService: ProductsService) { }

    @Get()
    @UseGuards(OptionalAuthGuard)
    @ApiOperation({ summary: 'Get all products with filters' })
    @ApiResponse({ status: 200, description: 'Return all products' })
    @ApiQuery({ name: 'search', required: false })
    @ApiQuery({ name: 'categoryId', required: false })
    @ApiQuery({ name: 'condition', enum: ProductCondition, required: false })
    @ApiQuery({ name: 'status', enum: ProductStatus, required: false })
    @ApiQuery({ name: 'minPrice', type: Number, required: false })
    @ApiQuery({ name: 'maxPrice', type: Number, required: false })
    @ApiQuery({ name: 'sortBy', enum: ['price', 'createdAt'], required: false })
    @ApiQuery({ name: 'order', enum: ['asc', 'desc'], required: false })
    @ApiQuery({ name: 'sellerId', required: false })
    async findAll(@Req() req: Request, @Res() res: Response, @Query() query: ProductQuery) {
        const userId = (req.user as any)?.sub;
        const { data, total } = await this.productsService.findAll(query, userId);

        res.setHeader('X-Total-Count', total);
        res.setHeader('Access-Control-Expose-Headers', 'X-Total-Count');
        return res.json(data);
    }

    @Get(':id')
    @UseGuards(OptionalAuthGuard)
    @ApiOperation({ summary: 'Get a product by id' })
    @ApiResponse({ status: 200, description: 'Return the product' })
    @ApiResponse({ status: 404, description: 'Product not found' })
    findOne(@Param('id') id: string, @Req() req: Request) {
        const userId = (req.user as any)?.sub;
        return this.productsService.findOne(id, userId);
    }

    @Post()
    @UseGuards(AuthGuard('jwt'))
    @ApiBearerAuth()
    @ApiOperation({ summary: 'Create a new product' })
    @ApiResponse({ status: 201, description: 'Product successfully created' })
    create(
        @Body() createProductDto: CreateProductDto,
        @GetCurrentUser('sub') userId: string,
    ) {
        return this.productsService.create(createProductDto, userId);
    }

    @Patch(':id')
    @UseGuards(AuthGuard('jwt'))
    @ApiBearerAuth()
    @ApiOperation({ summary: 'Update a product' })
    @ApiResponse({ status: 200, description: 'Product successfully updated' })
    update(
        @Param('id') id: string,
        @Body() updateProductDto: UpdateProductDto,
        @GetCurrentUser() user: any,
    ) {
        return this.productsService.update(id, updateProductDto, user.sub, user.role);
    }

    @Delete(':id')
    @UseGuards(AuthGuard('jwt'))
    @ApiBearerAuth()
    @ApiOperation({ summary: 'Delete a product' })
    @ApiResponse({ status: 200, description: 'Product successfully deleted' })
    remove(
        @Param('id') id: string,
        @GetCurrentUser('sub') userId: string,
    ) {
        return this.productsService.remove(id, userId);
    }

    @Post(':id/reviews')
    @UseGuards(AuthGuard('jwt'))
    @ApiBearerAuth()
    @ApiOperation({ summary: 'Add a review to a product' })
    @ApiResponse({ status: 201, description: 'Review successfully created' })
    addReview(
        @Param('id') id: string,
        @GetCurrentUser('sub') userId: string,
        @Body() body: { rating: number, comment?: string },
    ) {
        return this.productsService.addReview(id, userId, body.rating, body.comment);
    }

    @Post(':id/comments')
    @UseGuards(AuthGuard('jwt'))
    @ApiBearerAuth()
    @ApiOperation({ summary: 'Add a comment to a product' })
    @ApiResponse({ status: 201, description: 'Comment successfully created' })
    addComment(
        @Param('id') id: string,
        @GetCurrentUser('sub') userId: string,
        @Body() body: { content: string },
    ) {
        return this.productsService.addComment(id, userId, body.content);
    }

    @Patch(':id/status')
    @UseGuards(AuthGuard('jwt'), RolesGuard)
    @Roles(Role.ADMIN)
    @ApiBearerAuth()
    @ApiOperation({ summary: 'Update product status (Admin only)' })
    @ApiResponse({ status: 200, description: 'Product status successfully updated' })
    updateStatus(
        @Param('id') id: string,
        @Body() body: { status: ProductStatus, moderationComment?: string },
    ) {
        return this.productsService.updateStatus(id, body.status, body.moderationComment);
    }
}
