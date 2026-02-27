import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();
async function check() {
    const categories = await prisma.category.findMany({
        where: { level: 2 },
        select: { id: true, name: true, possibleSizes: true, sizeType: true }
    });
    console.log(JSON.stringify(categories, null, 2));
}
check().catch(console.error).finally(() => prisma.$disconnect());
