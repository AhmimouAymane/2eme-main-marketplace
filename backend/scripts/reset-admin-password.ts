import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
    const email = 'iahmimou2006@gmail.com';
    const newPassword = 'CloviAdmin2024!'; // 15 chars, Meets all requirements

    const user = await prisma.user.findUnique({
        where: { email }
    });

    if (!user) {
        console.error(`User ${email} not found.`);
        return;
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await prisma.user.update({
        where: { id: user.id },
        data: {
            password: hashedPassword,
            role: 'ADMIN',
            isEmailVerified: true
        }
    });

    console.log(`Successfully reset password for ${email} to: ${newPassword}`);
    console.log('Role set to ADMIN and email verified.');
}

main()
    .catch(e => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
