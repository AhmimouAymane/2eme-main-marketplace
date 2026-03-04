import { IsString } from 'class-validator';

export class RejectVerificationDto {
    @IsString()
    comment: string;
}
