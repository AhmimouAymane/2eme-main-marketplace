import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();
async function main() {
    const slugsToCheck = ['women', 'men', 'enfant', 'femme', 'homme', 'kids'];
    const cats = await prisma.category.findMany({
        where: { level: 0 }
    });
    console.log('Top Level Categories:');
    cats.forEach(c => console.log(`- ID: ${c.id}, Name: ${c.name}, Slug: ${c.slug}`));
}
main().finally(() => prisma.$disconnect());
