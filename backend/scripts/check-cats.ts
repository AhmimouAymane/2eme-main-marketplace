import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();
async function main() {
    const cats = await prisma.category.findMany({ where: { level: 0 } });
    console.log('Top Level Categories:');
    cats.forEach(c => console.log(`- ${c.name} (slug: ${c.slug})`));
}
main().finally(() => prisma.$disconnect());
