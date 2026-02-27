import { PrismaClient, SizeType, ProductCondition, ProductStatus, Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
    console.log('Seeding categories...');

    // Nettoyer les anciennes données pour éviter les conflits de clé étrangère
    console.log('Cleaning up old data...');
    await prisma.notification.deleteMany();
    await prisma.message.deleteMany();
    await prisma.conversation.deleteMany();
    await prisma.order.deleteMany();
    await prisma.userReview.deleteMany();
    await prisma.review.deleteMany();
    await prisma.favorite.deleteMany();
    await prisma.comment.deleteMany();
    await prisma.productImage.deleteMany();
    await prisma.product.deleteMany();
    await prisma.category.deleteMany();

    const genreData = [
        { name: 'Femme', slug: 'femme' },
        { name: 'Homme', slug: 'homme' },
        { name: 'Enfants', slug: 'enfants' },
    ];

    for (const g of genreData) {
        const genre = await prisma.category.upsert({
            where: { slug: g.slug },
            update: { name: g.name },
            create: { name: g.name, slug: g.slug, level: 0 },
        });

        if (g.slug === 'femme') {
            await createCategoryWithSubs(genre.id, 'Vêtements', 'femme-vetements', [
                { name: 'Hauts', slug: 'femme-vetements-hauts', sizeType: SizeType.ALPHA },
                { name: 'Robes', slug: 'femme-vetements-robes', sizeType: SizeType.ALPHA },
                { name: 'Pantalons', slug: 'femme-vetements-pantalons', sizeType: SizeType.NUMERIC_PANTS },
                { name: 'Jupes', slug: 'femme-vetements-jupes', sizeType: SizeType.ALPHA },
                { name: 'Vestes & Manteaux', slug: 'femme-vetements-vestes', sizeType: SizeType.ALPHA },
            ]);
            await createCategoryWithSubs(genre.id, 'Chaussures', 'femme-chaussures', [
                { name: 'Sneakers', slug: 'femme-chaussures-sneakers', sizeType: SizeType.NUMERIC_SHOES },
                { name: 'Talons', slug: 'femme-chaussures-talons', sizeType: SizeType.NUMERIC_SHOES },
                { name: 'Sandales', slug: 'femme-chaussures-sandales', sizeType: SizeType.NUMERIC_SHOES },
                { name: 'Bottes', slug: 'femme-chaussures-bottes', sizeType: SizeType.NUMERIC_SHOES },
            ]);
            await createCategoryWithSubs(genre.id, 'Sacs & Accessoires', 'femme-accessoires', [
                { name: 'Sacs', slug: 'femme-accessoires-sacs', sizeType: SizeType.ONE_SIZE },
                { name: 'Bijoux', slug: 'femme-accessoires-bijoux', sizeType: SizeType.ONE_SIZE },
                { name: 'Ceintures', slug: 'femme-accessoires-ceintures', sizeType: SizeType.ALPHA },
                { name: 'Lunettes', slug: 'femme-accessoires-lunettes', sizeType: SizeType.ONE_SIZE },
            ]);
            await createCategoryWithSubs(genre.id, 'Lingerie & Pyjama', 'femme-lingerie', [
                { name: 'Lingerie', slug: 'femme-lingerie-lingerie', sizeType: SizeType.ALPHA },
                { name: 'Pyjamas', slug: 'femme-lingerie-pyjamas', sizeType: SizeType.ALPHA },
            ]);
            await createCategoryWithSubs(genre.id, 'Activewear', 'femme-activewear', [
                { name: 'Tenues sport', slug: 'femme-activewear-sport', sizeType: SizeType.ALPHA },
            ]);
            await createCategoryWithSubs(genre.id, 'Maillots de bain', 'femme-maillots', [
                { name: '2 pièces', slug: 'femme-maillots-2pieces', sizeType: SizeType.ALPHA },
                { name: '1 pièce', slug: 'femme-maillots-1piece', sizeType: SizeType.ALPHA },
            ]);
            await createCategoryWithSubs(genre.id, 'Traditionnel', 'femme-traditionnel', [
                { name: 'Caftan', slug: 'femme-traditionnel-caftan', sizeType: SizeType.ALPHA },
                { name: 'Takchita', slug: 'femme-traditionnel-takchita', sizeType: SizeType.ALPHA },
                { name: 'Djellaba', slug: 'femme-traditionnel-djellaba', sizeType: SizeType.ALPHA },
            ]);
        } else if (g.slug === 'homme') {
            await createCategoryWithSubs(genre.id, 'Vêtements', 'homme-vetements', [
                { name: 'Hauts', slug: 'homme-vetements-hauts', sizeType: SizeType.ALPHA },
                { name: 'Pantalons', slug: 'homme-vetements-pantalons', sizeType: SizeType.NUMERIC_PANTS },
                { name: 'Shorts', slug: 'homme-vetements-shorts', sizeType: SizeType.NUMERIC_PANTS },
                { name: 'Vestes & Manteaux', slug: 'homme-vetements-vestes', sizeType: SizeType.ALPHA },
                { name: 'Costumes', slug: 'homme-vetements-costumes', sizeType: SizeType.NUMERIC_PANTS },
            ]);
            await createCategoryWithSubs(genre.id, 'Chaussures', 'homme-chaussures', [
                { name: 'Sneakers', slug: 'homme-chaussures-sneakers', sizeType: SizeType.NUMERIC_SHOES },
                { name: 'Chaussures ville', slug: 'homme-chaussures-ville', sizeType: SizeType.NUMERIC_SHOES },
                { name: 'Sandales', slug: 'homme-chaussures-sandales', sizeType: SizeType.NUMERIC_SHOES },
            ]);
            await createCategoryWithSubs(genre.id, 'Accessoires', 'homme-accessoires', [
                { name: 'Sacs', slug: 'homme-accessoires-sacs', sizeType: SizeType.ONE_SIZE },
                { name: 'Ceintures', slug: 'homme-accessoires-ceintures', sizeType: SizeType.ALPHA },
                { name: 'Montres', slug: 'homme-accessoires-montres', sizeType: SizeType.ONE_SIZE },
                { name: 'Casquettes', slug: 'homme-accessoires-casquettes', sizeType: SizeType.ONE_SIZE },
            ]);
            await createCategoryWithSubs(genre.id, 'Activewear', 'homme-activewear', [
                { name: 'Tenues sport', slug: 'homme-activewear-sport', sizeType: SizeType.ALPHA },
            ]);
            await createCategoryWithSubs(genre.id, 'Traditionnel', 'homme-traditionnel', [
                { name: 'Djellaba', slug: 'homme-traditionnel-djellaba', sizeType: SizeType.ALPHA },
                { name: 'Jabador', slug: 'homme-traditionnel-jabador', sizeType: SizeType.ALPHA },
            ]);
        } else if (g.slug === 'enfants') {
            const fille = await prisma.category.upsert({
                where: { slug: 'enfants-fille' },
                update: { name: 'FILLE' },
                create: { name: 'FILLE', slug: 'enfants-fille', level: 1, parentId: genre.id },
            });
            await createSubs(fille.id, [
                { name: 'Vêtements', slug: 'enfants-fille-vetements', sizeType: SizeType.AGE },
                { name: 'Chaussures', slug: 'enfants-fille-chaussures', sizeType: SizeType.NUMERIC_SHOES },
                { name: 'Accessoires', slug: 'enfants-fille-accessoires', sizeType: SizeType.ONE_SIZE },
                { name: 'Traditionnel', slug: 'enfants-fille-traditionnel', sizeType: SizeType.AGE },
            ]);

            const garcon = await prisma.category.upsert({
                where: { slug: 'enfants-garcon' },
                update: { name: 'GARÇON' },
                create: { name: 'GARÇON', slug: 'enfants-garcon', level: 1, parentId: genre.id },
            });
            await createSubs(garcon.id, [
                { name: 'Vêtements', slug: 'enfants-garcon-vetements', sizeType: SizeType.AGE },
                { name: 'Chaussures', slug: 'enfants-garcon-chaussures', sizeType: SizeType.NUMERIC_SHOES },
                { name: 'Accessoires', slug: 'enfants-garcon-accessoires', sizeType: SizeType.ONE_SIZE },
                { name: 'Traditionnel', slug: 'enfants-garcon-traditionnel', sizeType: SizeType.AGE },
            ]);
        }
    }

    // Le reste du seed (User, Produits) peut être adapté si besoin, 
    // mais ici on se concentre sur les catégories.
    console.log('Seed completed successfully!');
}

async function createCategoryWithSubs(parentId: string, name: string, slug: string, subs: any[]) {
    const parent = await prisma.category.upsert({
        where: { slug },
        update: { name },
        create: { name, slug, level: 1, parentId },
    });
    await createSubs(parent.id, subs);
}

const DEFAULT_SIZES = {
    [SizeType.ALPHA]: ['XXS', 'XS', 'S', 'M', 'L', 'XL', 'XXL'],
    [SizeType.NUMERIC_SHOES]: ['35', '36', '37', '38', '39', '40', '41', '42', '43', '44', '45'],
    [SizeType.NUMERIC_PANTS]: ['32', '34', '36', '38', '40', '42', '44', '46', '48', '50'],
    [SizeType.AGE]: ['Naissance', '1 mois', '3 mois', '6 mois', '9 mois', '12 mois', '18 mois', '2 ans', '3 ans', '4 ans', '5 ans', '6 ans', '8 ans', '10 ans', '12 ans'],
    [SizeType.ONE_SIZE]: [],
};

async function createSubs(parentId: string, subs: any[]) {
    for (const sub of subs) {
        const possibleSizes = sub.sizeType ? DEFAULT_SIZES[sub.sizeType as SizeType] : [];
        await prisma.category.upsert({
            where: { slug: sub.slug },
            update: {
                name: sub.name,
                sizeType: sub.sizeType,
                possibleSizes: possibleSizes
            },
            create: {
                name: sub.name,
                slug: sub.slug,
                level: 2,
                parentId,
                sizeType: sub.sizeType,
                possibleSizes: possibleSizes
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
