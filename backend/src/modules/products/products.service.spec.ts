import { Test, TestingModule } from '@nestjs/testing';
import { ProductsService } from './products.service';
import { PrismaService } from '../prisma/prisma.service';
import { NotFoundException } from '@nestjs/common';
import { MediaService } from '../media/media.service';

const mockPrismaService = {
    product: {
        findMany: jest.fn(),
        findUnique: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
    },
};

const mockMediaService = {
    deleteFiles: jest.fn().mockResolvedValue(undefined),
};

describe('ProductsService', () => {
    let service: ProductsService;
    let prisma: PrismaService;

    beforeEach(async () => {
        const module: TestingModule = await Test.createTestingModule({
            providers: [
                ProductsService,
                {
                    provide: PrismaService,
                    useValue: mockPrismaService,
                },
                {
                    provide: MediaService,
                    useValue: mockMediaService,
                },
            ],
        }).compile();

        service = module.get<ProductsService>(ProductsService);
        prisma = module.get<PrismaService>(PrismaService);
    });

    it('should be defined', () => {
        expect(service).toBeDefined();
    });

    describe('findAll', () => {
        it('should return an array of products', async () => {
            const result = [
                { id: '1', title: 'Product 1', seller: { id: 's1' }, category: 'MEN', status: 'FOR_SALE' },
            ];
            mockPrismaService.product.findMany.mockResolvedValue(result);

            expect(await service.findAll({})).toBe(result);
            expect(mockPrismaService.product.findMany).toHaveBeenCalled();
        });
    });

    describe('findOne', () => {
        it('should return a product if it exists', async () => {
            const result = { id: '1', title: 'Product 1', images: [], reviews: [], comments: [] };
            mockPrismaService.product.findUnique.mockResolvedValue(result);

            expect(await service.findOne('1')).toBe(result);
        });

        it('should throw NotFoundException if product does not exist', async () => {
            mockPrismaService.product.findUnique.mockResolvedValue(null);

            await expect(service.findOne('1')).rejects.toThrow(NotFoundException);
        });
    });

    describe('create', () => {
        it('should create a new product', async () => {
            const createProductDto = {
                title: 'New Product',
                price: 10,
                description: 'Desc',
                category: 'MEN',
                size: 'L',
                brand: 'Brand',
                condition: 'VERY_GOOD',
                images: ['url1']
            };
            const sellerId = 's1';
            const result = { id: '1', ...createProductDto, sellerId };

            mockPrismaService.product.create.mockResolvedValue(result);

            expect(await service.create(createProductDto as any, sellerId)).toBe(result);
            expect(mockPrismaService.product.create).toHaveBeenCalledWith({
                data: expect.objectContaining({
                    title: 'New Product',
                    sellerId: 's1',
                    images: {
                        create: [{ url: 'url1' }]
                    }
                }),
                include: { images: true }
            });
        });
    });

    describe('update', () => {
        it('should update a product', async () => {
            const updateProductDto = { title: 'Updated Product' };
            const existingProduct = { id: '1', title: 'Old Product', sellerId: 's1' };
            const result = { id: '1', title: 'Updated Product' };

            jest.spyOn(service, 'findOne').mockResolvedValue(existingProduct as any);
            mockPrismaService.product.update.mockResolvedValue(result);

            expect(await service.update('1', updateProductDto, 's1')).toBe(result);
            expect(mockPrismaService.product.update).toHaveBeenCalledWith({
                where: { id: '1' },
                data: {
                    title: 'Updated Product',
                    images: undefined,
                },
                include: { images: true },
            });
        });
    });

    describe('remove', () => {
        it('should remove a product', async () => {
            const existingProduct = { id: '1', title: 'Product to delete', sellerId: 's1' };
            const result = { id: '1', title: 'Product to delete' };

            jest.spyOn(service, 'findOne').mockResolvedValue(existingProduct as any);
            mockPrismaService.product.delete.mockResolvedValue(result);

            expect(await service.remove('1', 's1')).toBe(result);
            expect(mockPrismaService.product.delete).toHaveBeenCalledWith({
                where: { id: '1' },
            });
        });
    });
});
