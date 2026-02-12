import { IsString, IsNotEmpty, IsNumber, IsOptional, Min, IsEnum, IsArray } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { ProductCondition, ProductStatus } from '@prisma/client';

export class CreateProductDto {
    @ApiProperty({ example: 'iPhone 15 Pro' })
    @IsString()
    @IsNotEmpty()
    title: string;

    @ApiProperty({ example: 'The latest iPhone with titanium design.' })
    @IsString()
    @IsNotEmpty()
    description: string;

    @ApiProperty({ example: 999.99 })
    @IsNumber()
    @Min(0)
    price: number;

    @ApiProperty({ example: 'uuid-of-category', description: 'ID of the sub-category' })
    @IsString()
    @IsNotEmpty()
    categoryId: string;

    @ApiProperty({ example: 'L' })
    @IsString()
    @IsNotEmpty()
    size: string;

    @ApiProperty({ example: 'Nike' })
    @IsString()
    @IsNotEmpty()
    brand: string;

    @ApiProperty({ enum: ProductCondition, example: ProductCondition.VERY_GOOD })
    @IsEnum(ProductCondition)
    condition: ProductCondition;

    @ApiProperty({ enum: ProductStatus, example: ProductStatus.FOR_SALE, default: ProductStatus.FOR_SALE })
    @IsEnum(ProductStatus)
    @IsOptional()
    status?: ProductStatus;

    @ApiProperty({
        type: [String],
        example: ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
        required: false
    })
    @IsArray()
    @IsString({ each: true })
    @IsOptional()
    images?: string[];

    @ApiProperty({
        type: [String],
        example: ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
        required: false
    })
    @IsArray()
    @IsString({ each: true })
    @IsOptional()
    imageUrls?: string[];
}
