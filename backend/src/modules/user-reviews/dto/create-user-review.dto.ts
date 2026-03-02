import { IsInt, IsString, IsOptional, Min, Max, IsUUID } from 'class-validator';

export class CreateUserReviewDto {
    @IsUUID()
    orderId: string;

    @IsInt()
    @Min(1)
    @Max(5)
    rating: number;

    @IsString()
    @IsOptional()
    comment?: string;
}
