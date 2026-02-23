import { IsEmail, IsNotEmpty, IsString, IsEnum, MinLength } from 'class-validator';
import { VerificationType } from '@prisma/client';

export class ForgotPasswordDto {
    @IsEmail()
    @IsNotEmpty()
    email: string;
}

export class VerifyOtpDto {
    @IsEmail()
    @IsNotEmpty()
    email: string;

    @IsString()
    @IsNotEmpty()
    @MinLength(6)
    code: string;

    @IsEnum(VerificationType)
    @IsNotEmpty()
    type: VerificationType;
}

export class ResetPasswordDto {
    @IsEmail()
    @IsNotEmpty()
    email: string;

    @IsString()
    @IsNotEmpty()
    @MinLength(6)
    code: string;

    @IsString()
    @IsNotEmpty()
    @MinLength(6)
    newPassword: string;
}
