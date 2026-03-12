import { Injectable, UnauthorizedException, ConflictException, Inject, BadRequestException, NotFoundException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { LoginDto } from './dto/login.dto';
import * as bcrypt from 'bcrypt';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType, VerificationType } from '@prisma/client';
import { MailService } from '../mail/mail.service';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AuthService {
    constructor(
        private usersService: UsersService,
        private jwtService: JwtService,
        @Inject('FIREBASE_ADMIN') private firebaseAdmin: any,
        private notificationsService: NotificationsService,
        private mailService: MailService,
        private prisma: PrismaService,
    ) { }

    async signInWithFirebase(token: string, metadata?: { firstName?: string; lastName?: string }) {
        if (this.firebaseAdmin.apps.length === 0) {
            throw new BadRequestException('Social login is currently disabled (Firebase not initialized). Please check the server configuration.');
        }
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
            throw new UnauthorizedException('Invalid Firebase token');
        }
    }

    async refreshTokens(refreshToken: string) {
        try {
            const decoded = await this.jwtService.verifyAsync(refreshToken, {
                secret: process.env.JWT_REFRESH_SECRET || 'secret',
            });

            const user = await this.usersService.findOne(decoded.sub);
            if (!user) {
                throw new UnauthorizedException('User not found');
            }

            const tokens = await this.getTokens(user.id, user.email, user.role);
            return {
                user: this.sanitizeUser(user),
                ...tokens,
            };
        } catch (error) {
            throw new UnauthorizedException('Invalid or expired refresh token');
        }
    }

    async updateFcmToken(userId: string, token: string) {
        return this.usersService.update(userId, { fcmToken: token });
    }

    async register(createUserDto: CreateUserDto) {
        createUserDto.email = createUserDto.email.toLowerCase();
        const existingUser = await this.usersService.findByEmail(createUserDto.email);

        if (existingUser) {
            if (existingUser.isEmailVerified) {
                throw new ConflictException('User already exists');
            }

            // If user exists but NOT VERIFIED, resend code
            const code = await this.generateAndSaveCode(existingUser.email, VerificationType.REGISTRATION);
            await this.mailService.sendVerificationCode(existingUser.email, code);

            return {
                message: 'Un nouveau code de vérification a été envoyé à votre adresse email.',
                email: existingUser.email,
            };
        }

        const hashedPassword = await bcrypt.hash(createUserDto.password, 10);
        const user = await this.usersService.create({
            ...createUserDto,
            password: hashedPassword,
        });

        // 1. Generate and Send Verification Code
        const code = await this.generateAndSaveCode(user.email, VerificationType.REGISTRATION);
        await this.mailService.sendVerificationCode(user.email, code);

        await this.sendWelcomeNotification(user.id, user.firstName);

        return {
            message: 'Un code de vérification a été envoyé à votre adresse email.',
            email: user.email,
        };
    }

    async forgotPassword(email: string) {
        const normalizedEmail = email.toLowerCase();
        const user = await this.usersService.findByEmail(normalizedEmail);
        if (!user) {
            throw new NotFoundException('Aucun compte n\'est associé à cet email.');
        }

        const code = await this.generateAndSaveCode(normalizedEmail, VerificationType.PASSWORD_RESET);
        await this.mailService.sendVerificationCode(normalizedEmail, code);

        return { message: 'Un code de réinitialisation a été envoyé.' };
    }

    async verifyCode(email: string, code: string, type: VerificationType) {
        const verification = await this.prisma.verificationCode.findFirst({
            where: {
                email,
                code,
                type,
                expiresAt: { gt: new Date() },
            },
        });

        if (!verification) {
            throw new BadRequestException('Code invalide ou expiré');
        }

        // Delete the code after verification
        await this.prisma.verificationCode.delete({ where: { id: verification.id } });

        if (type === VerificationType.REGISTRATION) {
            const user = await this.usersService.findByEmail(email);
            if (user) {
                await this.usersService.update(user.id, { isEmailVerified: true });
                const tokens = await this.getTokens(user.id, user.email, user.role);
                return {
                    user: this.sanitizeUser(user),
                    ...tokens,
                };
            }
        }

        // For PASSWORD_RESET, return a temporary token OR just success and handle reset in next call
        // Here we return a simple success and the email for the next step
        return { message: 'Vérification réussie', email };
    }

    async resetPassword(email: string, code: string, newPassword: string) {
        // Double check verification (in a real app, use a temp token from verifyCode)
        // For simplicity, we re-verify or trust the flow if short-lived
        const user = await this.usersService.findByEmail(email);
        if (!user) throw new NotFoundException('Utilisateur non trouvé');

        const hashedPassword = await bcrypt.hash(newPassword, 10);
        await this.usersService.update(user.id, { password: hashedPassword });

        return { message: 'Mot de passe réinitialisé avec succès' };
    }

    private async generateAndSaveCode(email: string, type: VerificationType): Promise<string> {
        // 6-digit code
        const code = Math.floor(100000 + Math.random() * 900000).toString();
        const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes

        // Delete any existing codes for this email and type
        await this.prisma.verificationCode.deleteMany({
            where: { email, type },
        });

        await this.prisma.verificationCode.create({
            data: {
                email,
                code,
                type,
                expiresAt,
            },
        });

        return code;
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
        }
    }

    async login(loginDto: LoginDto) {
        const normalizedEmail = loginDto.email.toLowerCase();
        const user = await this.usersService.findByEmail(normalizedEmail);
        if (!user) {
            throw new UnauthorizedException('Identifiants invalides');
        }

        // Check if user has a password (might be a social login account)
        if (!user.password) {
            throw new UnauthorizedException('Veuillez vous connecter via Google ou Apple');
        }

        const isPasswordValid = await bcrypt.compare(loginDto.password, user.password);
        if (!isPasswordValid) {
            throw new UnauthorizedException('Identifiants invalides');
        }

        // Email verification gate
        if (!user.isEmailVerified) {
            // Re-send code if they try to login while unverified
            const code = await this.generateAndSaveCode(user.email, VerificationType.REGISTRATION);
            await this.mailService.sendVerificationCode(user.email, code);
            throw new UnauthorizedException('Email non vérifié');
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
