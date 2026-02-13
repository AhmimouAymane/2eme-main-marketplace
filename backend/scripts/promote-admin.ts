import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    const users = await prisma.user.findMany({
        select: { id: true, email: true, role: true }
    });

    if (users.length === 0) {
        console.log('No users found in database.');
        return;
    }

    console.log('Current users:');
    users.forEach(u => console.log(`- ${u.email} (${u.role})`));

    // Promote the first user to ADMIN if no admin exists
    const hasAdmin = users.some(u => u.role === 'ADMIN');
    if (!hasAdmin) {
        const firstUser = users[0];
        await prisma.user.update({
            where: { id: firstUser.id },
            data: { role: 'ADMIN' }
        });
        console.log(`\nPromoted ${firstUser.email} to ADMIN.`);
    } else {
        console.log('\nAn admin already exists.');
    }
}

main()
    .catch(e => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
