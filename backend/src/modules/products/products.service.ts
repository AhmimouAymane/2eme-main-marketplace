import { Injectable, NotFoundException, ForbiddenException, InternalServerErrorException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { Product, ProductCondition, ProductStatus } from '@prisma/client';

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
    @IsOptional()
    condition?: ProductCondition;

    @IsOptional()
    @IsEnum(ProductStatus)
    @IsOptional()
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
}

import { MediaService } from '../media/media.service';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType } from '@prisma/client';

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
            sortBy = 'createdAt',
            order = 'desc',
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

        const products = await this.prisma.product.findMany({
            where: {
                deletedAt: null,
                status: status || (sellerId ? undefined : ProductStatus.FOR_SALE),
                categoryId: categoryIds.length > 0 ? { in: categoryIds } : undefined,
                size: size || undefined,
                brand: brand ? { contains: brand, mode: 'insensitive' } : undefined,
                condition: condition || undefined,
                sellerId: sellerId || undefined,
                price: {
                    gte: minPrice ? Number(minPrice) : undefined,
                    lte: maxPrice ? Number(maxPrice) : undefined,
                },
                OR: search ? [
                    { title: { contains: search, mode: 'insensitive' } },
                    { description: { contains: search, mode: 'insensitive' } },
                    { brand: { contains: search, mode: 'insensitive' } },
                ] : undefined,
            },
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
            orderBy: { [sortBy]: order },
        });

        if (userId) {
            const userFavorites = await this.prisma.favorite.findMany({
                where: { userId },
                select: { productId: true }
            });
            const favoriteIds = new Set(userFavorites.map(f => f.productId));
            return (products as any).map((p: any) => ({
                ...p,
                isFavorite: favoriteIds.has(p.id)
            }));
        }

        return (products as any).map((p: any) => ({ ...p, isFavorite: false }));
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
        const { images, imageUrls, ...data } = createProductDto;
        const imagesToSave = imageUrls || images;

        return this.prisma.product.create({
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
    }

    async update(id: string, updateProductDto: UpdateProductDto, userId: string) {
        const product = await this.findOne(id);

        if (product.sellerId !== userId) {
            throw new NotFoundException(`Product not found or you're not the owner`);
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

        return this.prisma.product.update({
            where: { id },
            data: {
                ...data,
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
        if (status === ProductStatus.FOR_SALE) {
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
