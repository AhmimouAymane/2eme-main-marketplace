import {
    Controller,
    Get,
    Post,
    Body,
    Patch,
    Param,
    UseGuards,
    Query,
    Res,
} from '@nestjs/common';
import type { Response } from 'express';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { OrdersService } from './orders.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { UpdateOrderDto } from './dto/update-order.dto';
import { AuthGuard } from '@nestjs/passport';
import { GetCurrentUser } from '../../common/decorators/get-current-user.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@ApiTags('orders')
@Controller('orders')
@UseGuards(AuthGuard('jwt'))
@ApiBearerAuth()
export class OrdersController {
    constructor(private readonly ordersService: OrdersService) { }

    @Post()
    @ApiOperation({ summary: 'Create a new order' })
    @ApiResponse({ status: 201, description: 'Order successfully created' })
    create(
        @Body() createOrderDto: CreateOrderDto,
        @GetCurrentUser('sub') userId: string,
    ) {
        return this.ordersService.create(createOrderDto, userId);
    }

    @Get()
    @UseGuards(AuthGuard('jwt'), RolesGuard)
    @Roles(Role.ADMIN)
    @ApiOperation({ summary: 'Get all orders (Admin only)' })
    async findAllAdmin(
        @Query() query: { _start?: number; _end?: number; _sort?: string; _order?: string },
        @Res() res: Response,
    ) {
        const { data, total } = await this.ordersService.findAllForAdmin(query);
        res.setHeader('X-Total-Count', total);
        res.setHeader('Access-Control-Expose-Headers', 'X-Total-Count');
        return res.json(data);
    }

    @Get('buyer')
    @ApiOperation({ summary: 'Get orders as buyer' })
    findAllAsBuyer(@GetCurrentUser('sub') userId: string) {
        return this.ordersService.findAll(userId, 'buyer');
    }

    @Get('seller')
    @ApiOperation({ summary: 'Get orders as seller' })
    findAllAsSeller(@GetCurrentUser('sub') userId: string) {
        return this.ordersService.findAll(userId, 'seller');
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get an order by id' })
    findOne(
        @Param('id') id: string,
        @GetCurrentUser('sub') userId: string,
    ) {
        return this.ordersService.findOne(id, userId);
    }

    @Patch(':id')
    @ApiOperation({ summary: 'Update an order' })
    update(
        @Param('id') id: string,
        @Body() updateOrderDto: UpdateOrderDto,
        @GetCurrentUser('sub') userId: string,
    ) {
        return this.ordersService.update(id, updateOrderDto, userId);
    }
}
