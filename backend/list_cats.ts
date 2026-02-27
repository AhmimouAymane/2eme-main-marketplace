import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    const categories = await prisma.category.findMany({
        select: {
            id: true,
            name: true,
            slug: true,
            level: true,
            parentId: true,
        }
    });
    console.log('---CAT_START---');
    console.log(JSON.stringify(categories, null, 2));
    console.log('---CAT_END---');
}

main()
    .catch(e => console.error(e))
    .finally(async () => {
        await prisma.$disconnect();
    });
