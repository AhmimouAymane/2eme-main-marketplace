import { IsEnum, IsOptional, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { OrderStatus } from '@prisma/client';

export class UpdateOrderDto {
    @ApiProperty({ enum: OrderStatus, example: OrderStatus.CONFIRMED })
    @IsEnum(OrderStatus)
    @IsOptional()
    status?: OrderStatus;

    @ApiProperty({ example: 'New shipping address', required: false })
    @IsString()
    @IsOptional()
    shippingAddress?: string;

    @ApiProperty({ example: 'Seller pickup address', required: false })
    @IsString()
    @IsOptional()
    pickupAddress?: string;
}
