import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    const counts = await prisma.product.groupBy({
        by: ['status'],
        _count: {
            id: true
        },
        where: {
            deletedAt: null
        }
    });

    console.log('Product counts by status:');
    counts.forEach(c => {
        console.log(`- ${c.status}: ${c._count.id}`);
    });

    const total = await prisma.product.count({ where: { deletedAt: null } });
    console.log(`\nTotal non-deleted products: ${total}`);
}

main()
    .catch(e => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
