import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();
async function main() {
    const products = await prisma.product.findMany({ include: { category: true } });
    console.log('Products and their Categories:');
    products.forEach(p => {
        console.log(`- ${p.title} | Category: ${p.category.name} | Slug: ${p.category.slug}`);
    });
}
main().finally(() => prisma.$disconnect());
