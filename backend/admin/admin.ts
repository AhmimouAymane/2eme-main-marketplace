import 'reflect-metadata';
import express from 'express';
import AdminJS from 'adminjs';
import * as AdminJSExpress from '@adminjs/express';
import { Database, Resource } from '@adminjs/prisma';
import { PrismaClient } from '@prisma/client';

AdminJS.registerAdapter({ Database, Resource });

const prisma = new PrismaClient();

const admin = new AdminJS({
  resources: [
    { resource: { model: prisma.user, client: prisma }, options: { navigation: 'Utilisateurs' } },
    { resource: { model: prisma.product, client: prisma }, options: { navigation: 'Marketplace' } },
    { resource: { model: prisma.order, client: prisma }, options: { navigation: 'Marketplace' } },
    { resource: { model: prisma.conversation, client: prisma }, options: { navigation: 'Messagerie' } },
    { resource: { model: prisma.message, client: prisma }, options: { navigation: 'Messagerie' } },
    { resource: { model: prisma.favorite, client: prisma }, options: { navigation: 'Marketplace' } },
    { resource: { model: prisma.review, client: prisma }, options: { navigation: 'Marketplace' } },
    { resource: { model: prisma.comment, client: prisma }, options: { navigation: 'Marketplace' } },
  ],
  rootPath: '/admin',
  branding: {
    companyName: '2ème Main',
  },
});

const app = express();

const ADMIN = {
  email: process.env.ADMIN_EMAIL || 'admin@example.com',
  password: process.env.ADMIN_PASSWORD || 'admin123',
};

const adminRouter = AdminJSExpress.buildAuthenticatedRouter(admin, {
  authenticate: async (email, password) =>
    email === ADMIN.email && password === ADMIN.password ? ADMIN : null,
  cookieName: 'adminjs',
  cookiePassword: process.env.ADMIN_COOKIE_SECRET || 'admin-secret',
});

app.use(admin.options.rootPath, adminRouter);

const PORT = process.env.ADMIN_PORT || 3001;
app.listen(PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`AdminJS is running at http://localhost:${PORT}${admin.options.rootPath}`);
});

