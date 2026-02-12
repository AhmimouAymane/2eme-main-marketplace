import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';
import { PrismaService } from '../src/modules/prisma/prisma.service';
import * as bcrypt from 'bcrypt';
import { Category, ProductCondition } from '@prisma/client';

describe('ProductsController (e2e)', () => {
    let app: INestApplication;
    let prisma: PrismaService;
    let accessToken: string;
    let userId: string;

    beforeAll(async () => {
        const moduleFixture: TestingModule = await Test.createTestingModule({
            imports: [AppModule],
        }).compile();

        app = moduleFixture.createNestApplication();
        await app.init();

        prisma = app.get<PrismaService>(PrismaService);

        // Create a test user with hashed password
        const hashedPassword = await bcrypt.hash('password', 10);
        const user = await prisma.user.upsert({
            where: { email: 'test_e2e@example.com' },
            update: { password: hashedPassword },
            create: {
                email: 'test_e2e@example.com',
                firstName: 'Test',
                lastName: 'User',
                password: hashedPassword,
                role: 'USER',
            },
        });
        userId = user.id;

        // Login to get token
        const loginResponse = await request(app.getHttpServer())
            .post('/auth/login')
            .send({ email: 'test_e2e@example.com', password: 'password' });

        accessToken = loginResponse.body.accessToken;
    });

    afterAll(async () => {
        await app.close();
    });

    describe('/products (GET)', () => {
        it('should return all products', () => {
            return request(app.getHttpServer())
                .get('/products')
                .expect(200);
        });
    });

    describe('/products (POST)', () => {
        it('should create a new product', async () => {
            const productData = {
                title: 'E2E Test Product',
                description: 'Testing products e2e',
                price: 99.99,
                category: Category.MEN,
                size: 'L',
                brand: 'Nike',
                condition: ProductCondition.VERY_GOOD,
                images: ['http://example.com/image.jpg'],
            };

            const response = await request(app.getHttpServer())
                .post('/products')
                .set('Authorization', `Bearer ${accessToken}`)
                .send(productData)
                .expect(201);

            expect(response.body.title).toBe(productData.title);
            expect(response.body.sellerId).toBe(userId);
            expect(response.body.category).toBe(productData.category);
            expect(response.body.images).toHaveLength(1);
        });

        it('should fail if not authenticated', () => {
            return request(app.getHttpServer())
                .post('/products')
                .send({ title: 'Unauthorized Product' })
                .expect(401);
        });
    });

    describe('/products/:id (GET)', () => {
        it('should return a product by id', async () => {
            const product = await prisma.product.create({
                data: {
                    title: 'Find Me',
                    description: 'Find me',
                    price: 10,
                    category: Category.WOMEN,
                    size: 'M',
                    brand: 'Adidas',
                    condition: ProductCondition.NEW_WITH_TAGS,
                    sellerId: userId,
                },
            });

            const response = await request(app.getHttpServer())
                .get(`/products/${product.id}`)
                .expect(200);

            expect(response.body.id).toBe(product.id);
            expect(response.body.title).toBe('Find Me');
        });
    });
});
