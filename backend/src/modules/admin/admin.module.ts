import { Module, DynamicModule } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import * as bcrypt from 'bcrypt';

@Module({})
export class AdminModule {
    static async createAsync(): Promise<DynamicModule> {
        // Import dynamique des modules ESM
        const AdminJS = (await import('adminjs')).default;
        const AdminJSPrisma = await import('@adminjs/prisma');
        const { Database, Resource } = AdminJSPrisma;
        const AdminJSNestjs = await import('@adminjs/nestjs');

        // Enregistrer l'adaptateur Prisma
        AdminJS.registerAdapter({ Database, Resource });

        const prisma = new PrismaService();

        const adminJs = new AdminJS({
            resources: [
                {
                    resource: { model: prisma.user, client: prisma },
                    options: {
                        navigation: { name: '👥 Users', icon: 'User' },
                        properties: {
                            password: { isVisible: false },
                            role: {
                                availableValues: [
                                    { value: 'USER', label: 'User' },
                                    { value: 'ADMIN', label: 'Admin' },
                                ],
                            },
                        },
                    },
                },
                {
                    resource: { model: prisma.product, client: prisma },
                    options: {
                        navigation: { name: '🏬 Products', icon: 'ShoppingBag' },
                    },
                },
                {
                    resource: { model: prisma.order, client: prisma },
                    options: {
                        navigation: { name: '🛒 Orders', icon: 'ShoppingCart' },
                    },
                },
                {
                    resource: { model: prisma.category, client: prisma },
                    options: {
                        navigation: { name: '🗃️ Categories', icon: 'Folder' },
                    },
                },
                {
                    resource: { model: prisma.conversation, client: prisma },
                    options: {
                        navigation: { name: '💬 Chat', icon: 'MessageCircle' },
                    },
                },
                {
                    resource: { model: prisma.message, client: prisma },
                    options: {
                        navigation: { name: '💬 Chat', icon: 'MessageSquare' },
                    },
                },
                {
                    resource: { model: prisma.review, client: prisma },
                    options: {
                        navigation: { name: '⭐ Reviews', icon: 'Star' },
                    },
                },
                {
                    resource: { model: prisma.favorite, client: prisma },
                    options: {
                        navigation: { name: '❤️ Favorites', icon: 'Heart' },
                    },
                },
            ],
            rootPath: '/admin',
            branding: {
                companyName: 'Marketplace Admin',
                logo: false,
            },
        });

        const router = AdminJSNestjs.AdminModule.createAdmin({
            adminJsOptions: {
                rootPath: '/admin',
                resources: adminJs.options.resources,
                branding: adminJs.options.branding,
            },
            auth: {
                authenticate: async (email: string, password: string) => {
                    const user = await prisma.user.findUnique({ where: { email } });
                    if (!user || user.role !== 'ADMIN') {
                        return null;
                    }
                    const isValid = await bcrypt.compare(password, user.password);
                    return isValid ? { email: user.email, id: user.id } : null;
                },
                cookieName: 'adminjs',
                cookiePassword: process.env.JWT_ACCESS_SECRET || 'secret-key-change-in-production',
            },
            sessionOptions: {
                resave: false,
                saveUninitialized: false,
                secret: process.env.JWT_ACCESS_SECRET || 'secret-key-change-in-production',
            },
        });

        return {
            module: AdminModule,
            imports: [router],
        };
    }
}
