import { PrismaClient, SizeType, ProductCondition, ProductStatus, Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
    console.log('Seeding categories...');

    // Reset categories (optional, be careful in prod)
    // await prisma.category.deleteMany();

    const genres = [
        { name: 'Femme', slug: 'women' },
        { name: 'Homme', slug: 'men' },
        { name: 'Enfant', slug: 'kids' },
    ];

    for (const genreData of genres) {
        const genre = await prisma.category.upsert({
            where: { slug: genreData.slug },
            update: {},
            create: {
                name: genreData.name,
                slug: genreData.slug,
                level: 0,
            },
        });

        // Detailed categories based on user request example
        if (genre.slug === 'women') {
            await createCategory(genre.id, 'Vêtements', 'women-clothing', [
                { name: 'Robes', slug: 'women-dresses', sizeType: SizeType.ALPHA },
                { name: 'T-shirts', slug: 'women-tshirts', sizeType: SizeType.ALPHA },
                { name: 'Jeans', slug: 'women-jeans', sizeType: SizeType.NUMERIC_PANTS },
                { name: 'Manteaux & Vestes', slug: 'women-coats', sizeType: SizeType.ALPHA },
            ]);
            await createCategory(genre.id, 'Chaussures', 'women-shoes', [
                { name: 'Baskets', slug: 'women-sneakers', sizeType: SizeType.NUMERIC_SHOES },
                { name: 'Escarpins', slug: 'women-heels', sizeType: SizeType.NUMERIC_SHOES },
                { name: 'Bottes', slug: 'women-boots', sizeType: SizeType.NUMERIC_SHOES },
            ]);
        } else if (genre.slug === 'men') {
            await createCategory(genre.id, 'Vêtements', 'men-clothing', [
                { name: 'T-shirts', slug: 'men-tshirts', sizeType: SizeType.ALPHA },
                { name: 'Pantalons', slug: 'men-pants', sizeType: SizeType.NUMERIC_PANTS },
                { name: 'Costumes', slug: 'men-suits', sizeType: SizeType.NUMERIC_PANTS },
            ]);
            await createCategory(genre.id, 'Chaussures', 'men-shoes', [
                { name: 'Baskets', slug: 'men-sneakers', sizeType: SizeType.NUMERIC_SHOES },
                { name: 'Ville', slug: 'men-formal-shoes', sizeType: SizeType.NUMERIC_SHOES },
            ]);
        } else if (genre.slug === 'kids') {
            await createCategory(genre.id, 'Fille', 'kids-girls', [
                { name: 'Robes', slug: 'kids-girls-dresses', sizeType: SizeType.AGE },
                { name: 'T-shirts', slug: 'kids-girls-tshirts', sizeType: SizeType.AGE },
            ]);
            await createCategory(genre.id, 'Garçon', 'kids-boys', [
                { name: 'T-shirts', slug: 'kids-boys-tshirts', sizeType: SizeType.AGE },
                { name: 'Pantalons', slug: 'kids-boys-pants', sizeType: SizeType.AGE },
            ]);
        }
    }

    console.log('Seeding users...');
    const hashedPassword = await bcrypt.hash('password123', 10);
    const user = await prisma.user.upsert({
        where: { email: 'test@example.com' },
        update: {},
        create: {
            email: 'test@example.com',
            password: hashedPassword,
            firstName: 'Ayman',
            lastName: 'Seller',
            role: Role.USER,
        },
    });

    console.log('Seeding products...');
    const tshirts = await prisma.category.findUnique({ where: { slug: 'men-tshirts' } });
    const jeans = await prisma.category.findUnique({ where: { slug: 'women-jeans' } });
    const sneakers = await prisma.category.findUnique({ where: { slug: 'men-sneakers' } });

    const products = [
        {
            title: 'T-shirt Nike coton',
            description: 'Un t-shirt confortable 100% coton',
            price: 25.0,
            categoryId: tshirts!.id,
            size: 'L',
            brand: 'Nike',
            condition: ProductCondition.VERY_GOOD,
            status: ProductStatus.FOR_SALE,
            sellerId: user.id,
            images: ['https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=500'],
        },
        {
            title: 'Levi\'s 501 Original',
            description: 'Jean levi\'s classique peu porté',
            price: 55.0,
            categoryId: jeans!.id,
            size: 'W32 L32',
            brand: 'Levi\'s',
            condition: ProductCondition.GOOD,
            status: ProductStatus.FOR_SALE,
            sellerId: user.id,
            images: ['https://images.unsplash.com/photo-1542272604-787c3835535d?w=500'],
        },
        {
            title: 'Adidas Stan Smith',
            description: 'Baskets blanches iconiques',
            price: 45.0,
            categoryId: sneakers!.id,
            size: '42',
            brand: 'Adidas',
            condition: ProductCondition.NEW_WITHOUT_TAGS,
            status: ProductStatus.FOR_SALE,
            sellerId: user.id,
            images: ['https://images.unsplash.com/photo-1587563871167-1ee9c731aefb?w=500'],
        },
        {
            title: 'T-shirt Vintage Band',
            description: 'Rare vintage band t-shirt',
            price: 80.0,
            categoryId: tshirts!.id,
            size: 'M',
            brand: 'Vintage',
            condition: ProductCondition.FAIR,
            status: ProductStatus.FOR_SALE,
            sellerId: user.id,
            images: ['https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=500'],
        },
    ];

    for (const p of products) {
        const { images, ...data } = p;
        await prisma.product.create({
            data: {
                ...data,
                images: {
                    create: images.map(url => ({ url }))
                }
            }
        });
    }

    console.log('Seed completed successfully!');
}

async function createCategory(parentId: string, name: string, slug: string, subCategories: any[]) {
    const category = await prisma.category.upsert({
        where: { slug },
        update: {},
        create: {
            name,
            slug,
            level: 1,
            parentId,
        },
    });

    for (const sub of subCategories) {
        await prisma.category.upsert({
            where: { slug: sub.slug },
            update: {},
            create: {
                name: sub.name,
                slug: sub.slug,
                level: 2,
                parentId: category.id,
                sizeType: sub.sizeType,
            },
        });
    }
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
