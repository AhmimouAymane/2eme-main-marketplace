import { PrismaClient } from '@prisma/client';

async function main() {
    const prisma = new PrismaClient();
    const user = await prisma.user.findFirst();
    if (user) {
        console.log(`FOUND_USER_ID:${user.id}`);
    } else {
        console.log('NO_USER_FOUND');
    }
    await prisma.$disconnect();
}

main();
