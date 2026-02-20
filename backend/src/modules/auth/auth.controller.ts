import { Body, Controller, Post, HttpCode, HttpStatus, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { LoginDto } from './dto/login.dto';
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

    @Post('fcm-token')
    @UseGuards(AuthGuard('jwt'))
    @HttpCode(HttpStatus.OK)
    @ApiOperation({ summary: 'Update FCM token' })
    updateFcmToken(@Request() req: any, @Body('token') token: string) {
        return this.authService.updateFcmToken(req.user.sub || req.user.id, token);
    }
}
