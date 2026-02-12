import { Test, TestingModule } from '@nestjs/testing';
import { ProductsController } from './products.controller';
import { ProductsService } from './products.service';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';

const mockProductsService = {
    findAll: jest.fn(),
    findOne: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    remove: jest.fn(),
};

describe('ProductsController', () => {
    let controller: ProductsController;
    let service: ProductsService;

    beforeEach(async () => {
        const module: TestingModule = await Test.createTestingModule({
            controllers: [ProductsController],
            providers: [
                {
                    provide: ProductsService,
                    useValue: mockProductsService,
                },
            ],
        }).compile();

        controller = module.get<ProductsController>(ProductsController);
        service = module.get<ProductsService>(ProductsService);
    });

    it('should be defined', () => {
        expect(controller).toBeDefined();
    });

    describe('findAll', () => {
        it('should return an array of products', async () => {
            const result = [{ id: '1', title: 'Product 1' }];
            mockProductsService.findAll.mockResolvedValue(result);

            expect(await controller.findAll({ query: {} } as any, {})).toBe(result);
            expect(service.findAll).toHaveBeenCalledWith({});
        });
    });

    describe('findOne', () => {
        it('should return a single product', async () => {
            const result = { id: '1', title: 'Product 1' };
            mockProductsService.findOne.mockResolvedValue(result);

            expect(await controller.findOne('1', { user: {} } as any)).toBe(result);
            expect(service.findOne).toHaveBeenCalledWith('1', undefined);
        });
    });

    describe('create', () => {
        it('should create a new product', async () => {
            const createProductDto: CreateProductDto = {
                title: 'New Product',
                price: 10,
                description: 'Desc',
                category: 'MEN',
                size: 'L',
                brand: 'Brand',
                condition: 'VERY_GOOD'
            } as any;
            const userId = 'user1';
            const result = { id: '1', ...createProductDto, sellerId: userId };
            mockProductsService.create.mockResolvedValue(result);

            expect(await controller.create(createProductDto, userId)).toBe(result);
            expect(service.create).toHaveBeenCalledWith(createProductDto, userId);
        });
    });

    describe('update', () => {
        it('should update a product', async () => {
            const updateProductDto: UpdateProductDto = { title: 'Updated Product' };
            const result = { id: '1', ...updateProductDto };
            mockProductsService.update.mockResolvedValue(result);

            expect(await controller.update('1', updateProductDto, 'user1')).toBe(result);
            expect(service.update).toHaveBeenCalledWith('1', updateProductDto, 'user1');
        });
    });

    describe('remove', () => {
        it('should remove a product', async () => {
            const result = { id: '1', title: 'Deleted product' };
            mockProductsService.remove.mockResolvedValue(result);

            expect(await controller.remove('1', 'user1')).toBe(result);
            expect(service.remove).toHaveBeenCalledWith('1', 'user1');
        });
    });
});
