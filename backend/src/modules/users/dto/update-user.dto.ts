import { IsString, IsOptional, MaxLength } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateUserDto {
    @ApiPropertyOptional({ example: 'John' })
    @IsString()
    @IsOptional()
    firstName?: string;

    @ApiPropertyOptional({ example: 'Doe' })
    @IsString()
    @IsOptional()
    lastName?: string;

    @ApiPropertyOptional({ example: '+1234567890' })
    @IsString()
    @IsOptional()
    phone?: string;


    @ApiPropertyOptional({ example: 'https://example.com/avatar.jpg' })
    @IsString()
    @IsOptional()
    avatarUrl?: string;

    @ApiPropertyOptional({ example: 'I love selling high-quality clothes.' })
    @IsString()
    @IsOptional()
    @MaxLength(500)
    bio?: string;
}
