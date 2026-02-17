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
    const { ComponentLoader } = await import('adminjs');
    const path = await import('path');
    console.log('[AdminJS] Step 2: Registering adapter...');

    AdminJS.registerAdapter({
      Database: AdminJSPrisma.Database,
      Resource: AdminJSPrisma.Resource,
    });

    const componentLoader = new ComponentLoader();
    const IMAGE_PREVIEW = componentLoader.add('ImagePreview', path.join(process.cwd(), 'src/admin/components/image-preview'));
    const IMAGE_SHOW = componentLoader.add('ImageShow', path.join(process.cwd(), 'src/admin/components/image-show'));

    const prisma = new PrismaClient();
    const getModel = (name: string) => Prisma.dmmf.datamodel.models.find((m: any) => m.name === name);
    console.log('[AdminJS] Step 3: Creating AdminJS instance...');

    const admin = new AdminJS({
      componentLoader,
      resources: [
        {
          resource: { model: getModel('User'), client: prisma },
          options: {
            navigation: { name: 'Utilisateurs', icon: 'User', parent: { name: 'Paramètres', icon: 'Settings' } },
            properties: { password: { isVisible: false } },
          },
        },
        {
          resource: { model: getModel('Product'), client: prisma },
          options: {
            navigation: { name: 'Produits', icon: 'ShoppingBag', parent: { name: 'Modération', icon: 'CheckSquare' } },
            actions: {
              approve: {
                actionType: 'record',
                icon: 'Check',
                handler: async (request: any, response: any, context: any) => {
                  const { record, resource } = context;
                  await record.update({ status: 'FOR_SALE' });
                  return {
                    record: record.toJSON(context.currentAdmin),
                    notice: { message: 'Produit approuvé avec succès', type: 'success' },
                    redirectUrl: resource.recordURL({ recordId: record.id() }),
                  };
                },
                component: false,
              },
              reject: {
                actionType: 'record',
                icon: 'X',
                handler: async (request: any, response: any, context: any) => {
                  const { record, resource } = context;
                  if (request.method === 'get') {
                    return { record: record.toJSON(context.currentAdmin) };
                  }
                  const { moderationComment } = request.payload;
                  if (!moderationComment) {
                    return {
                      record: record.toJSON(context.currentAdmin),
                      notice: { message: 'Un motif est requis pour rejeter le produit', type: 'error' },
                    };
                  }
                  await record.update({ status: 'REJECTED', moderationComment });
                  return {
                    record: record.toJSON(context.currentAdmin),
                    notice: { message: 'Produit rejeté', type: 'success' },
                    redirectUrl: resource.recordURL({ recordId: record.id() }),
                  };
                },
              },
            },
            properties: {
              status: {
                position: 1,
                availableValues: [
                  { value: 'PENDING_APPROVAL', label: 'En attente' },
                  { value: 'FOR_SALE', label: 'Publié' },
                  { value: 'REJECTED', label: 'Rejeté' },
                  { value: 'RESERVED', label: 'Réservé' },
                  { value: 'SOLD', label: 'Vendu' },
                ],
              },
              title: { position: 2 },
              price: { position: 3 },
              moderationComment: {
                type: 'textarea',
                isVisible: { list: false, filter: false, show: true, edit: true },
              },
            },
          },
        },
        {
          resource: { model: getModel('ProductImage'), client: prisma },
          options: {
            navigation: { name: 'Images', icon: 'Image', parent: { name: 'Modération', icon: 'CheckSquare' } },
            properties: {
              url: {
                isVisible: { list: true, show: true, edit: true, filter: false },
                components: {
                  list: IMAGE_PREVIEW,
                  show: IMAGE_SHOW,
                }
              }
            }
          }
        },
        {
          resource: { model: getModel('Order'), client: prisma },
          options: {
            navigation: { name: 'Commandes', icon: 'ShoppingCart', parent: { name: 'Gestion', icon: 'Briefcase' } }
          },
        },
        {
          resource: { model: getModel('Category'), client: prisma },
          options: {
            navigation: { name: 'Catégories', icon: 'Folder', parent: { name: 'Paramètres', icon: 'Settings' } },
            properties: {
              id: { isVisible: true },
              name: { isVisible: true },
              slug: { isVisible: true },
              level: { isVisible: true },
              parentId: { isVisible: true },
              sizeType: { isVisible: true },
            }
          },
        },
        {
          resource: { model: getModel('Conversation'), client: prisma },
          options: {
            navigation: { name: 'Conversations', icon: 'MessageCircle', parent: { name: 'Messagerie', icon: 'Mail' } }
          },
        },
        {
          resource: { model: getModel('Message'), client: prisma },
          options: {
            navigation: { name: 'Messages', icon: 'MessageSquare', parent: { name: 'Messagerie', icon: 'Mail' } }
          },
        },
        {
          resource: { model: getModel('Review'), client: prisma },
          options: {
            navigation: { name: 'Avis', icon: 'Star', parent: { name: 'Modération', icon: 'CheckSquare' } }
          },
        },
        {
          resource: { model: getModel('Favorite'), client: prisma },
          options: {
            navigation: { name: 'Favoris', icon: 'Heart', parent: { name: 'Gestion', icon: 'Briefcase' } }
          },
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
  const host = process.env.HOST || '0.0.0.0';
  await app.listen(port, host);
  console.log(`Application is running on: http://localhost:${port}/api/v1`);
  if (host === '0.0.0.0') {
    console.log('Listening on all interfaces — use your PC IP (e.g. http://192.168.x.x:' + port + '/api/v1) from phone/emulator');
  }
  console.log(`Swagger documentation: http://localhost:${port}/api/docs`);
  console.log(`AdminJS panel: http://localhost:${port}/admin`);
}
bootstrap();
