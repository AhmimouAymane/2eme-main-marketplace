import { Injectable, UnauthorizedException, ConflictException, Inject } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { LoginDto } from './dto/login.dto';
import * as bcrypt from 'bcrypt';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType } from '@prisma/client';

@Injectable()
export class AuthService {
    constructor(
        private usersService: UsersService,
        private jwtService: JwtService,
        @Inject('FIREBASE_ADMIN') private firebaseAdmin: any,
        private notificationsService: NotificationsService,
    ) { }

    async signInWithFirebase(token: string, metadata?: { firstName?: string; lastName?: string }) {
        try {
            const decodedToken = await this.firebaseAdmin.auth().verifyIdToken(token);
            const { email, name, picture, uid } = decodedToken;

            if (!email) {
                throw new UnauthorizedException('Firebase token must contain an email');
            }

            let user = await this.usersService.findByEmail(email);
            let isNewUser = false;

            console.log(`[AuthService] signInWithFirebase: Received metadata for ${email}:`, metadata);

            // Split name from token into firstName and lastName if present
            const nameParts = (name || '').trim().split(' ');
            const tokenFirstName = nameParts[0] || '';
            const tokenLastName = nameParts.length > 1 ? nameParts.slice(1).join(' ') : '';

            // Fallback: If no name provided ANYWHERE, use email prefix
            const emailPrefix = email.split('@')[0];
            const capitalizedPrefix = emailPrefix.charAt(0).toUpperCase() + emailPrefix.slice(1);

            const finalFirstName = metadata?.firstName || tokenFirstName || capitalizedPrefix;
            const finalLastName = metadata?.lastName || tokenLastName || '';

            if (!user) {
                isNewUser = true;
                user = await this.usersService.create({
                    email,
                    firstName: finalFirstName,
                    lastName: finalLastName,
                    password: '', // Social login users don't have a password
                    avatarUrl: picture,
                });
            } else {
                // UPDATE LOGIC: Sync names even for existing users if they have placeholder names
                const currentFirstName = user.firstName.toLowerCase();
                const currentLastName = (user.lastName || '').toLowerCase();

                const isPlaceholder =
                    currentFirstName === 'user' ||
                    currentFirstName === 'firebase' ||
                    currentLastName === 'firebase' ||
                    currentFirstName === emailPrefix.toLowerCase();

                const updates: any = {};

                // If current name is a placeholder and we have a better one, update it
                if (isPlaceholder && finalFirstName && finalFirstName !== user.firstName) {
                    updates.firstName = finalFirstName;
                    updates.lastName = finalLastName;
                }

                // Always update avatar if missing and provided
                if (!user.avatarUrl && picture) {
                    updates.avatarUrl = picture;
                }

                if (Object.keys(updates).length > 0) {
                    console.log(`[AuthService] Updating user ${email}:`, updates);
                    user = await this.usersService.update(user.id, updates);
                }
            }

            if (isNewUser) {
                await this.sendWelcomeNotification(user.id, user.firstName);
            }

            const tokens = await this.getTokens(user.id, user.email, user.role);
            return {
                user: this.sanitizeUser(user),
                ...tokens,
            };
        } catch (error) {
            console.error('Firebase Auth Error:', error);
            throw new UnauthorizedException('Invalid Firebase token');
        }
    }

    async updateFcmToken(userId: string, token: string) {
        return this.usersService.update(userId, { fcmToken: token });
    }

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

        await this.sendWelcomeNotification(user.id, user.firstName);

        const tokens = await this.getTokens(user.id, user.email, user.role);
        return {
            user: this.sanitizeUser(user),
            ...tokens,
        };
    }

    private async sendWelcomeNotification(userId: string, firstName: string) {
        try {
            await this.notificationsService.create({
                userId,
                title: '👤 Bienvenue chez Clovi !',
                message: `Bonjour ${firstName}, ravi de vous compter parmi nous. Bon shopping !`,
                type: NotificationType.WELCOME,
            });
        } catch (error) {
            console.error('Welcome notification failed:', error);
        }
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

        const tokens = await this.getTokens(user.id, user.email, user.role);
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
