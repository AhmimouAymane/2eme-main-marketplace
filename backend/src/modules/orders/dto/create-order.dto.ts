import { IsString, IsNotEmpty, IsNumber, IsOptional, Min, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { OrderStatus } from '@prisma/client';

export class CreateOrderDto {
    @ApiProperty({ example: 'uuid-of-product' })
    @IsString()
    @IsNotEmpty()
    productId: string;

    @ApiProperty({ example: 999.99 })
    @IsNumber()
    @Min(0)
    totalPrice: number;

    @ApiProperty({ example: 50.0, required: false })
    @IsOptional()
    @IsNumber()
    @Min(0)
    serviceFee?: number;

    @ApiProperty({ example: 25.0, required: false })
    @IsOptional()
    @IsNumber()
    @Min(0)
    shippingFee?: number;

    @ApiProperty({ example: '123 rue Example, 75001 Paris', description: 'Adresse de livraison (obligatoire pour paiement à la livraison)' })
    @IsString()
    @IsNotEmpty({ message: 'L\'adresse de livraison est requise pour le paiement à la livraison' })
    shippingAddress: string;

    @ApiProperty({ enum: OrderStatus, example: OrderStatus.AWAITING_SELLER_CONFIRMATION, required: false })
    @IsOptional()
    @IsEnum(OrderStatus)
    status?: OrderStatus;
}
