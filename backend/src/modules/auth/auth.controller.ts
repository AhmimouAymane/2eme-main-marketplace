import { Body, Controller, Post, Get, Res, HttpCode, HttpStatus, UseGuards, Request } from '@nestjs/common';
import type { Response } from 'express';
import { VerificationType } from '@prisma/client';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { LoginDto } from './dto/login.dto';
import { ForgotPasswordDto, VerifyOtpDto, ResetPasswordDto } from './dto/otp-auth.dto';
import { AuthGuard } from '@nestjs/passport';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
    constructor(private authService: AuthService) { }

    @Post('register')
    @ApiOperation({ summary: 'Register a new user' })
    @ApiResponse({ status: 201, description: 'User successfully created' })
    @ApiResponse({ status: 409, description: 'User already exists' })
    register(@Body() createUserDto: CreateUserDto) {
        return this.authService.register(createUserDto);
    }

    @Post('login')
    @HttpCode(HttpStatus.OK)
    @ApiOperation({ summary: 'Login user' })
    @ApiResponse({ status: 200, description: 'User successfully logged in' })
    @ApiResponse({ status: 401, description: 'Invalid credentials' })
    login(@Body() loginDto: LoginDto) {
        return this.authService.login(loginDto);
    }

    @Post('forgot-password')
    @HttpCode(HttpStatus.OK)
    @ApiOperation({ summary: 'Request password reset OTP' })
    forgotPassword(@Body() forgotPasswordDto: ForgotPasswordDto) {
        return this.authService.forgotPassword(forgotPasswordDto.email);
    }

    @Post('verify-otp')
    @HttpCode(HttpStatus.OK)
    @ApiOperation({ summary: 'Verify OTP code' })
    verifyOtp(@Body() verifyOtpDto: VerifyOtpDto) {
        return this.authService.verifyCode(
            verifyOtpDto.email,
            verifyOtpDto.code,
            verifyOtpDto.type,
        );
    }

    @Post('reset-password')
    @HttpCode(HttpStatus.OK)
    @ApiOperation({ summary: 'Reset password using OTP' })
    resetPassword(@Body() resetPasswordDto: ResetPasswordDto) {
        return this.authService.resetPassword(
            resetPasswordDto.email,
            resetPasswordDto.code,
            resetPasswordDto.newPassword,
        );
    }

    @Post('firebase')
    @HttpCode(HttpStatus.OK)
    @ApiOperation({ summary: 'Authenticate with Firebase token' })
    @ApiResponse({ status: 200, description: 'Successfully authenticated' })
    @ApiResponse({ status: 401, description: 'Invalid Firebase token' })
    async signInWithFirebase(@Body() body: { token: string; firstName?: string; lastName?: string }) {
        return this.authService.signInWithFirebase(body.token, {
            firstName: body.firstName,
            lastName: body.lastName,
        });
    }

    @Post('refresh')
    @HttpCode(HttpStatus.OK)
    @ApiOperation({ summary: 'Refresh access token' })
    @ApiResponse({ status: 200, description: 'Tokens successfully refreshed' })
    @ApiResponse({ status: 401, description: 'Invalid refresh token' })
    async refresh(@Body('refreshToken') refreshToken: string) {
        return this.authService.refreshTokens(refreshToken);
    }

    @Post('fcm-token')
    @UseGuards(AuthGuard('jwt'))
    @HttpCode(HttpStatus.OK)
    @ApiOperation({ summary: 'Update FCM token' })
    updateFcmToken(@Request() req: any, @Body('token') token: string) {
        return this.authService.updateFcmToken(req.user.sub || req.user.id, token);
    }

    @Get('account-deletion')
    @ApiOperation({ summary: 'Web page explaining how to delete account (for Google Play compliance)' })
    getAccountDeletionPage(@Res() res: Response) {
        const html = `
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Clovi - Suppression de compte</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
        h1 { color: #10B981; }
        .card { background: #f9fafb; border: 1px solid #e5e7eb; border-radius: 8px; padding: 20px; margin-top: 20px; }
        .danger { color: #ef4444; font-weight: bold; }
    </style>
</head>
<body>
    <h1>Clovi - Demande de suppression de compte</h1>
    <p>Conformément aux directives de Google Play et à notre politique de confidentialité, vous avez le droit de demander la suppression de votre compte Clovi et de toutes vos données personnelles sans avoir à ouvrir l'application.</p>

    <div class="card">
        <h2>Comment supprimer votre compte ?</h2>
        <p>Veuillez envoyer un e-mail à notre équipe technique :</p>
        <p>📧 <strong>contact@clovi.ma</strong> (ou à votre adresse e-mail de contact)</p>
        <p><strong>Objet :</strong> Demande de suppression de compte</p>
        <p><strong>Message :</strong> Veuillez indiquer clairement votre souhait de supprimer votre compte en nous écrivant depuis l'adresse e-mail associée à celui-ci.</p>
    </div>

    <div class="card">
        <h2 class="danger">⚠️ Important : Que se passe-t-il ensuite ?</h2>
        <ul>
            <li>Votre demande sera traitée sous 72 heures ouvrées maximum.</li>
            <li>Vos informations de profil, vos annonces actives, vos favoris et vos messages seront définitivement effacés.</li>
            <li>Cependant, pour des raisons légales et comptables, certaines données de transactions (détails de commandes) peuvent être conservées.</li>
        </ul>
    </div>
</body>
</html>
        `;
        res.setHeader('Content-Type', 'text/html');
        return res.send(html);
    }
}
