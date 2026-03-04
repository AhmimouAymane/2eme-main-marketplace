import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function listAllCategories() {
    const categories = await prisma.category.findMany({
        select: { id: true, name: true, slug: true }
    });
    console.log(JSON.stringify(categories, null, 2));
}

listAllCategories().then(() => prisma.$disconnect());
