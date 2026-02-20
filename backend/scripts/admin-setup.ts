import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
    const args = process.argv.slice(2);
    const email = args[0];
    const password = args[1];

    if (!email || !password) {
        console.error('Usage: npx ts-node scripts/admin-setup.ts <email> <password>');
        process.exit(1);
    }

    const user = await prisma.user.findUnique({
        where: { email }
    });

    if (!user) {
        console.error(`User with email ${email} not found in database.`);
        process.exit(1);
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    await prisma.user.update({
        where: { id: user.id },
        data: {
            role: 'ADMIN',
            password: hashedPassword
        }
    });

    console.log(`Successfully promoted ${email} to ADMIN and updated local password.`);
    console.log('You can now log in to the /admin panel with these credentials.');
}

main()
    .catch(e => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
