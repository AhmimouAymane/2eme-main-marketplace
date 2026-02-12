import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { LoginDto } from './dto/login.dto';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
    constructor(
        private usersService: UsersService,
        private jwtService: JwtService,
    ) { }

    async register(createUserDto: CreateUserDto) {
        const existingUser = await this.usersService.findByEmail(createUserDto.email);
        if (existingUser) {
            throw new ConflictException('User already exists');
        }

        const hashedPassword = await bcrypt.hash(createUserDto.password, 10);
        const user = await this.usersService.create({
            ...createUserDto,
            password: hashedPassword,
        });

        const tokens = await this.getTokens(user.id, user.email, user.role);
        return {
            user: this.sanitizeUser(user),
            ...tokens,
        };
    }

    async login(loginDto: LoginDto) {
        const user = await this.usersService.findByEmail(loginDto.email);
        if (!user) {
            throw new UnauthorizedException('Invalid credentials');
        }

        const isPasswordValid = await bcrypt.compare(loginDto.password, user.password);
        if (!isPasswordValid) {
            throw new UnauthorizedException('Invalid credentials');
        }

        const tokens = await this.getTokens(user.id, user.id, user.role);
        return {
            user: this.sanitizeUser(user),
            ...tokens,
        };
    }

    private async getTokens(userId: string, email: string, role: string) {
        const [accessToken, refreshToken] = await Promise.all([
            this.jwtService.signAsync(
                { sub: userId, email, role } as any,
                {
                    secret: process.env.JWT_ACCESS_SECRET || 'secret',
                    expiresIn: (process.env.JWT_ACCESS_EXPIRATION || '1h') as any,
                },
            ),
            this.jwtService.signAsync(
                { sub: userId, email, role } as any,
                {
                    secret: process.env.JWT_REFRESH_SECRET || 'secret',
                    expiresIn: (process.env.JWT_REFRESH_EXPIRATION || '7d') as any,
                },
            ),
        ]);

        return {
            accessToken,
            refreshToken,
        };
    }

    private sanitizeUser(user: any) {
        const { password, ...result } = user;
        return result;
    }
}
