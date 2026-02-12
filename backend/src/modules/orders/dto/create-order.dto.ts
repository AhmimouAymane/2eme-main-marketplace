import { IsString, IsNotEmpty, IsNumber, IsOptional, Min } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateOrderDto {
    @ApiProperty({ example: 'uuid-of-product' })
    @IsString()
    @IsNotEmpty()
    productId: string;

    @ApiProperty({ example: 999.99 })
    @IsNumber()
    @Min(0)
    totalPrice: number;

    @ApiProperty({ example: '123 Main St, New York, NY 10001', required: false })
    @IsString()
    @IsOptional()
    shippingAddress?: string;
}
