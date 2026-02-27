import { PrismaClient, SizeType } from '@prisma/client';
const prisma = new PrismaClient();

const DEFAULT_SIZES = {
    [SizeType.ALPHA]: ['XXS', 'XS', 'S', 'M', 'L', 'XL', 'XXL'],
    [SizeType.NUMERIC_SHOES]: ['35', '36', '37', '38', '39', '40', '41', '42', '43', '44', '45'],
    [SizeType.NUMERIC_PANTS]: ['32', '34', '36', '38', '40', '42', '44', '46', '48', '50'],
    [SizeType.AGE]: ['Naissance', '1 mois', '3 mois', '6 mois', '9 mois', '12 mois', '18 mois', '2 ans', '3 ans', '4 ans', '5 ans', '6 ans', '8 ans', '10 ans', '12 ans'],
    [SizeType.ONE_SIZE]: [],
};

async function updateSizes() {
    console.log('Updating category possibleSizes surgically...');
    const categories = await prisma.category.findMany({
        where: { level: 2, sizeType: { not: null } }
    });

    for (const cat of categories) {
        if (cat.sizeType && (cat.possibleSizes.length === 0)) {
            const sizes = DEFAULT_SIZES[cat.sizeType as SizeType] || [];
            console.log(`Updating ${cat.name} (${cat.slug}) with sizes: ${sizes.join(', ')}`);
            await prisma.category.update({
                where: { id: cat.id },
                data: { possibleSizes: sizes }
            });
        }
    }
    console.log('Update complete!');
}

updateSizes().catch(console.error).finally(() => prisma.$disconnect());
