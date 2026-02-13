import { NestFactory } from '@nestjs/core';
import { ValidationPipe, VersioningType } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { WinstonModule } from 'nest-winston';
import * as winston from 'winston';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    logger: WinstonModule.createLogger({
      transports: [
        new winston.transports.Console({
          format: winston.format.combine(
            winston.format.timestamp(),
            winston.format.ms(),
            winston.format.colorize(),
            winston.format.simple(),
          ),
        }),
      ],
    }),
  });

  // Global prefix (exclude /admin for AdminJS)
  app.setGlobalPrefix('api', {
    exclude: ['admin', 'admin/(.*)'],
  });

  // API Versioning
  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: '1',
  });

  // Validation
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  // CORS
  app.enableCors({
    origin: process.env.FRONTEND_URL || '*',
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
  });

  // Swagger
  const config = new DocumentBuilder()
    .setTitle('Marketplace API')
    .setDescription('The marketplace API description')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  // ===== AdminJS Setup (BEFORE app.listen) =====
  try {
    console.log('[AdminJS] Step 1: Importing modules...');
    const AdminJS = (await import('adminjs')).default;
    const AdminJSExpress = await import('@adminjs/express');
    const AdminJSPrisma = await import('@adminjs/prisma');
    const { PrismaClient, Prisma } = await import('@prisma/client');
    const bcrypt = await import('bcrypt');
    console.log('[AdminJS] Step 2: Registering adapter...');

    AdminJS.registerAdapter({
      Database: AdminJSPrisma.Database,
      Resource: AdminJSPrisma.Resource,
    });

    const prisma = new PrismaClient();
    const getModel = (name: string) => Prisma.dmmf.datamodel.models.find((m: any) => m.name === name);
    console.log('[AdminJS] Step 3: Creating AdminJS instance...');

    const admin = new AdminJS({
      resources: [
        {
          resource: { model: getModel('User'), client: prisma },
          options: {
            navigation: { name: 'Users', icon: 'User' },
            properties: { password: { isVisible: false } },
          },
        },
        {
          resource: { model: getModel('Product'), client: prisma },
          options: { navigation: { name: 'Products', icon: 'ShoppingBag' } },
        },
        {
          resource: { model: getModel('Order'), client: prisma },
          options: { navigation: { name: 'Orders', icon: 'ShoppingCart' } },
        },
        {
          resource: { model: getModel('Category'), client: prisma },
          options: { navigation: { name: 'Categories', icon: 'Folder' } },
        },
        {
          resource: { model: getModel('Conversation'), client: prisma },
          options: { navigation: { name: 'Chat', icon: 'MessageCircle' } },
        },
        {
          resource: { model: getModel('Message'), client: prisma },
          options: { navigation: { name: 'Chat', icon: 'MessageSquare' } },
        },
        {
          resource: { model: getModel('Review'), client: prisma },
          options: { navigation: { name: 'Reviews', icon: 'Star' } },
        },
        {
          resource: { model: getModel('Favorite'), client: prisma },
          options: { navigation: { name: 'Favorites', icon: 'Heart' } },
        },
      ],
      rootPath: '/admin',
      branding: {
        companyName: 'Marketplace Admin',
        logo: false,
      },
    });
    console.log('[AdminJS] Step 4: Building router...');

    const adminRouter = AdminJSExpress.buildAuthenticatedRouter(admin, {
      authenticate: async (email: string, password: string) => {
        const user = await prisma.user.findUnique({ where: { email } });
        if (!user || user.role !== 'ADMIN') return null;
        const valid = await bcrypt.compare(password, user.password);
        return valid ? { email: user.email, id: user.id } : null;
      },
      cookieName: 'adminjs',
      cookiePassword: process.env.JWT_ACCESS_SECRET || 'secret-key-change-in-production',
    }, null, {
      resave: false,
      saveUninitialized: false,
      secret: process.env.JWT_ACCESS_SECRET || 'secret-key-change-in-production',
    });
    console.log('[AdminJS] Step 5: Mounting router...');

    app.use(admin.options.rootPath, adminRouter);
    console.log('[AdminJS] Mounted successfully');
  } catch (err) {
    console.error('[AdminJS] FAILED:', err);
  }

  const port = process.env.PORT || 8080;
  await app.listen(port);
  console.log(`Application is running on: http://localhost:${port}/api/v1`);
  console.log(`Swagger documentation: http://localhost:${port}/api/docs`);
  console.log(`AdminJS panel: http://localhost:${port}/admin`);
}
bootstrap();
