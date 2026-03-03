import { IsNumber, IsOptional, Min, Max } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdateSettingsDto {
    @ApiProperty({ example: 5.0, required: false })
    @IsOptional()
    @IsNumber()
    @Min(0)
    @Max(100)
    serviceFeePercentage?: number;

    @ApiProperty({ example: 25.0, required: false })
    @IsOptional()
    @IsNumber()
    @Min(0)
    shippingFee?: number;
}
