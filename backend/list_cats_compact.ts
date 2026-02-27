import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();
async function main() {
    const categories = await prisma.category.findMany({
        where: { level: 2 },
        select: { id: true, slug: true }
    });
    categories.forEach(c => console.log(`${c.id} | ${c.slug}`));
}
main().finally(() => prisma.$disconnect());
