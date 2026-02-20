import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();
async function main() {
    const cats = await prisma.category.findMany();
    console.log('All Categories:');
    cats.forEach(c => console.log(`- ${c.name} | Slug: ${c.slug} | Level: ${c.level} | ParentId: ${c.parentId}`));
}
main().finally(() => prisma.$disconnect());
