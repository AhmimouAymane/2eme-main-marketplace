import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function findTargetCategories() {
    const cats = await prisma.category.findMany();

    const targets = [
        { name: 'Bijoux', slug: 'bijoux' },
        { name: 'Chaussures femme', slug: 'femme-chaussures' },
        { name: 'Sacs', slug: 'sacs' }
    ];

    console.log('---TCS---');
    for (const t of targets) {
        const found = cats.find(c => c.slug === t.slug || c.name.toLowerCase().includes(t.name.toLowerCase()));
        if (found) {
            console.log(`${t.name}: ${found.id}`);
        }
    }
    console.log('---TCE---');
}

findTargetCategories().then(() => prisma.$disconnect());
