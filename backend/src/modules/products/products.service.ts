import { Injectable, NotFoundException, ForbiddenException, InternalServerErrorException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { Product, ProductCondition, ProductStatus, Role } from '@prisma/client';

import { IsOptional, IsString, IsNumber, IsEnum, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class ProductQuery {
    @IsOptional()
    @IsString()
    search?: string;

    @IsOptional()
    @IsString()
    categoryId?: string;

    @IsOptional()
    @IsString()
    size?: string;

    @IsOptional()
    @IsString()
    brand?: string;

    @IsOptional()
    @IsEnum(ProductCondition)
    condition?: ProductCondition;

    @IsOptional()
    @IsEnum(ProductStatus)
    status?: ProductStatus;

    @IsOptional()
    @IsString()
    sellerId?: string;

    @IsOptional()
    @Type(() => Number)
    @IsNumber()
    @Min(0)
    minPrice?: number;

    @IsOptional()
    @Type(() => Number)
    @IsNumber()
    @Min(0)
    maxPrice?: number;

    @IsOptional()
    @IsEnum(['price', 'createdAt'])
    sortBy?: 'price' | 'createdAt';

    @IsOptional()
    @IsEnum(['asc', 'desc'])
    order?: 'asc' | 'desc';

    // Refine / Simple-Rest parameters
    @IsOptional()
    @Type(() => Number)
    _start?: number;

    @IsOptional()
    @Type(() => Number)
    _end?: number;

    @IsOptional()
    @IsString()
    _sort?: string;

    @IsOptional()
    @IsString()
    _order?: string;
}

import { MediaService } from '../media/media.service';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType, Prisma } from '@prisma/client';

@Injectable()
export class ProductsService {
    constructor(
        private prisma: PrismaService,
        private mediaService: MediaService,
        private notificationsService: NotificationsService,
    ) { }

    async findAll(query: ProductQuery, userId?: string) {
        console.log('Fetching products with query:', query);
        const {
            search,
            categoryId,
            size,
            brand,
            condition,
            status,
            sellerId,
            minPrice,
            maxPrice,
            sortBy = query._sort || 'createdAt',
            order = query._order || 'desc',
        } = query;

        let categoryIds: string[] = [];
        if (categoryId) {
            // Get the category and all its descendants
            const allCategories = await this.prisma.category.findMany();

            const getDescendantIds = (parentId: string): string[] => {
                const children = allCategories.filter(c => c.parentId === parentId);
                let ids = [parentId];
                for (const child of children) {
                    ids = [...ids, ...getDescendantIds(child.id)];
                }
                return ids;
            };

            categoryIds = getDescendantIds(categoryId);
            console.log(`Filtering for category ${categoryId} and its descendants:`, categoryIds);
        }

        const where: Prisma.ProductWhereInput = {
            deletedAt: null,
            size: size || undefined,
            brand: brand ? { contains: brand, mode: 'insensitive' as Prisma.QueryMode } : undefined,
            condition: condition || undefined,
            sellerId: sellerId || undefined,
            price: {
                gte: minPrice ? Number(minPrice) : undefined,
                lte: maxPrice ? Number(maxPrice) : undefined,
            },
        };

        if (categoryIds.length > 0) {
            where.categoryId = { in: categoryIds };
        }

        const andConditions: Prisma.ProductWhereInput[] = [];

        // 1. Visibility rules
        // If it's explicitly an admin view (from admin panel), bypass filters
        if ((query as any).isAdminView === 'true' || (query as any).isAdminView === true) {
            // No additional status filters for admin panel
        } else if (userId) {
            const user = await this.prisma.user.findUnique({ where: { id: userId } });

            if (sellerId) {
                // When filtering by sellerId (e.g. "My Products" page),
                // show all statuses for the owner, PUBLISHED only for others
                if (sellerId === userId) {
                    // Owner viewing own products — show all statuses
                } else {
                    andConditions.push({ status: ProductStatus.PUBLISHED });
                }
            } else {
                // General feed (home page) — only PUBLISHED products for everyone on mobile
                andConditions.push({ status: ProductStatus.PUBLISHED });
            }
        } else {
            // Anonymous users only see available items
            andConditions.push({ status: ProductStatus.PUBLISHED });
        }

        // 2. Search logic (Title, Description, Brand)
        if (search) {
            andConditions.push({
                OR: [
                    { title: { contains: search, mode: 'insensitive' as Prisma.QueryMode } },
                    { description: { contains: search, mode: 'insensitive' as Prisma.QueryMode } },
                    { brand: { contains: search, mode: 'insensitive' as Prisma.QueryMode } },
                ]
            });
        }

        // 3. User requested status filter (if provided)
        if (status) {
            andConditions.push({ status });
        }

        if (andConditions.length > 0) {
            where.AND = andConditions;
        }

        const total = await this.prisma.product.count({ where });

        const products = await this.prisma.product.findMany({
            where,
            include: {
                images: true,
                category: true,
                seller: {
                    select: {
                        id: true,
                        firstName: true,
                        lastName: true,
                        email: true,
                        addresses: true,
                    },
                },
            },
            orderBy: { [sortBy]: (order as string).toLowerCase() },
            skip: query._start ? Number(query._start) : undefined,
            take: (query._end !== undefined && query._start !== undefined) ? (Number(query._end) - Number(query._start)) : undefined,
        });

        const result = (products as any).map((p: any) => ({
            ...p,
            isFavorite: userId ? false : false // Simplified for now
        }));

        return { data: result, total };
    }

    async findOne(id: string, userId?: string) {
        const product = await this.prisma.product.findFirst({
            where: { id, deletedAt: null },
            include: {
                images: true,
                category: true,
                reviews: {
                    include: {
                        user: {
                            select: { id: true, firstName: true, lastName: true },
                        },
                    },
                },
                comments: {
                    include: {
                        user: {
                            select: { id: true, firstName: true, lastName: true },
                        },
                    },
                },
                seller: {
                    select: {
                        id: true,
                        firstName: true,
                        lastName: true,
                        email: true,
                    },
                },
            },
        });

        if (!product) {
            throw new NotFoundException(`Product with ID ${id} not found`);
        }

        let isFavorite = false;
        if (userId) {
            const favorite = await this.prisma.favorite.findUnique({
                where: {
                    userId_productId: {
                        userId,
                        productId: id
                    }
                }
            });
            isFavorite = !!favorite;
        }

        return { ...product, isFavorite };
    }


    async create(createProductDto: CreateProductDto, sellerId: string) {
        console.log('--- PRODUCT CREATE DEBUG ---');
        console.log('Seller ID:', sellerId);
        console.log('Category ID:', createProductDto.categoryId);
        console.log('Title:', createProductDto.title);

        const { images, imageUrls, ...data } = createProductDto;
        const imagesToSave = imageUrls || images;

        try {
            const product = await this.prisma.product.create({
                data: {
                    ...data,
                    sellerId,
                    status: ProductStatus.PENDING_APPROVAL,
                    images: imagesToSave ? {
                        create: imagesToSave.map(url => ({ url })),
                    } : undefined,
                },
                include: {
                    images: true,
                },
            });
            console.log('Product created successfully:', product.id);
            return product;
        } catch (error) {
            console.error('Prisma Error in createProduct:', error);
            throw error;
        }
    }

    async update(id: string, updateProductDto: UpdateProductDto, userId: string, userRole?: string) {
        const product = await this.findOne(id);

        if (product.sellerId !== userId && userRole !== 'ADMIN') {
            throw new ForbiddenException(`Product not found or you're not the owner/admin`);
        }

        // Prevent updates when product has an active or completed order
        const lockedStatuses: ProductStatus[] = [ProductStatus.RESERVED, ProductStatus.CONFIRMED, ProductStatus.SOLD];
        if (lockedStatuses.includes(product.status) && userRole !== 'ADMIN') {
            throw new ForbiddenException('Ce produit ne peut pas être modifié car il a une commande en cours ou est déjà vendu.');
        }

        const { images, imageUrls, ...data } = updateProductDto;
        const imagesToSave = imageUrls || images;

        // Handle image deletion if images are updated
        if (imagesToSave) {
            // Find images that are in the current product but not in the new list
            // We need to compare full URLs or public IDs depending on what's stored
            // Assuming stored images are full URLs

            // Get current images
            const currentImages = (product as any).images.map((img: any) => img.url);

            // Identify images to delete (present in current but not in new list)
            const imagesToDelete = currentImages.filter((url: string) => !imagesToSave.includes(url));

            if (imagesToDelete.length > 0) {
                console.log(`Deleting ${imagesToDelete.length} images from Cloudinary`);
                // Execute deletion asynchronously without blocking the update
                this.mediaService.deleteFiles(imagesToDelete).catch(err => {
                    console.error('Failed to delete images from Cloudinary:', err);
                });
            }
        }

        // If product is REJECTED and is being updated, reset to PENDING_APPROVAL
        const newStatus = product.status === ProductStatus.REJECTED
            ? ProductStatus.PENDING_APPROVAL
            : undefined;

        return this.prisma.product.update({
            where: { id },
            data: {
                ...data,
                status: newStatus,
                images: imagesToSave ? {
                    deleteMany: {},
                    create: imagesToSave.map(url => ({ url })),
                } : undefined,
            },
            include: {
                images: true,
            },
        });
    }

    async remove(id: string, userId: string) {
        // ensure the product exists and retrieve owner
        const product = await this.findOne(id);
        if (product.sellerId !== userId) {
            // return a 403 Forbidden instead of generic error
            throw new ForbiddenException('You can only delete your own products');
        }

        // Prevent deletion when product has an active or completed order
        const lockedStatuses: ProductStatus[] = [ProductStatus.RESERVED, ProductStatus.CONFIRMED, ProductStatus.SOLD];
        if (lockedStatuses.includes(product.status)) {
            throw new ForbiddenException('Ce produit ne peut pas être supprimé car il a une commande en cours ou est déjà vendu.');
        }

        try {
            return await this.prisma.product.update({
                where: { id },
                data: { deletedAt: new Date() },
            });
        } catch (err) {
            // Prisma may throw for many reasons; log and wrap
            console.error('Error deleting product', id, err);
            // if it's a known Prisma error, you could inspect err.code
            throw new InternalServerErrorException('Unable to delete product at this time');
        }
    }

    async updateStatus(id: string, status: ProductStatus, moderationComment?: string) {
        const product = await this.prisma.product.update({
            where: { id },
            data: {
                status,
                moderationComment,
            },
        });

        // Trigger notification
        if (status === ProductStatus.PUBLISHED) {
            await this.notificationsService.create({
                userId: product.sellerId,
                title: '✅ Votre produit est en ligne !',
                message: `Votre article '${product.title}' a été approuvé et est visible par tous les acheteurs.`,
                type: NotificationType.PRODUCT_APPROVED,
                data: { productId: product.id, screen: 'product_detail' },
            });
        } else if (status === ProductStatus.REJECTED) {
            await this.notificationsService.create({
                userId: product.sellerId,
                title: '❌ Produit rejeté',
                message: `Votre article '${product.title}' a été rejeté. Motif : ${moderationComment || 'Non spécifié'}.`,
                type: NotificationType.PRODUCT_REJECTED,
                data: { productId: product.id, screen: 'my_products' },
            });
        }

        return product;
    }

    async addReview(productId: string, userId: string, rating: number, comment?: string) {
        return (this.prisma as any).review.upsert({
            where: {
                userId_productId: {
                    userId,
                    productId,
                },
            },
            update: {
                rating,
                comment,
            },
            create: {
                rating,
                comment,
                userId,
                productId,
            },
        });
    }

    async addComment(productId: string, userId: string, content: string) {
        return this.prisma.comment.create({
            data: {
                content,
                userId,
                productId,
            },
        });
    }
}
