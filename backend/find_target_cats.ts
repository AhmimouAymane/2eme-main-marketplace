import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function findCategories() {
    const categories = await prisma.category.findMany({
        select: { id: true, name: true, slug: true, parentId: true }
    });

    const targetNames = ['Bijoux', 'Chaussures', 'Sac', 'Femme'];

    for (const cat of categories) {
        for (const target of targetNames) {
            if (cat.name.toLowerCase().includes(target.toLowerCase())) {
                console.log(`CAT_FOUND: ${cat.name} | ID: ${cat.id} | SLUG: ${cat.slug}`);
            }
        }
    }
}

findCategories().then(() => prisma.$disconnect());
