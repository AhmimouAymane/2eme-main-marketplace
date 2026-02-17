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

    @ApiProperty({ example: '123 rue Example, 75001 Paris', description: 'Adresse de livraison (obligatoire pour paiement à la livraison)' })
    @IsString()
    @IsNotEmpty({ message: 'L\'adresse de livraison est requise pour le paiement à la livraison' })
    shippingAddress: string;
}
