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

@Injectable()
export class ProductsService {
    constructor(
        private prisma: PrismaService,
        private mediaService: MediaService,
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
            return products.map(p => ({
                ...p,
                isFavorite: favoriteIds.has(p.id)
            }));
        }

        return products.map(p => ({ ...p, isFavorite: false }));
    }

    async findOne(id: string, userId?: string) {
        const product = await this.prisma.product.findUnique({
            where: { id },
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
            const currentImages = product.images.map(img => img.url);

            // Identify images to delete (present in current but not in new list)
            const imagesToDelete = currentImages.filter(url => !imagesToSave.includes(url));

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
            return await this.prisma.product.delete({
                where: { id },
            });
        } catch (err) {
            // Prisma may throw for many reasons; log and wrap
            console.error('Error deleting product', id, err);
            // if it's a known Prisma error, you could inspect err.code
            throw new InternalServerErrorException('Unable to delete product at this time');
        }
    }

    async addReview(productId: string, userId: string, rating: number, comment?: string) {
        return this.prisma.review.create({
            data: {
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
