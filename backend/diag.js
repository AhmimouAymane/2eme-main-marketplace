const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    const result = {
        public: {},
        strapi: {},
        errors: []
    };

    try {
        const checkCount = async (table) => {
            try {
                const count = await prisma.$queryRawUnsafe(`SELECT COUNT(*) as count FROM ${table}`);
                return Number(count[0].count);
            } catch (e) {
                result.errors.push(`Count failed for ${table}: ${e.message}`);
                return null;
            }
        };

        result.public.users = await checkCount('public.users');
        result.public.products = await checkCount('public.products');

        result.strapi.user_accounts_view = await checkCount('strapi.user_accounts');
        result.strapi.products_view = await checkCount('strapi.products');

        result.tables = await prisma.$queryRawUnsafe(`
      SELECT table_schema, table_name, table_type 
      FROM information_schema.tables 
      WHERE table_schema IN ('public', 'strapi')
      AND table_name IN ('users', 'user_accounts', 'products', 'categories', 'orders')
    `);

        console.log(JSON.stringify(result, null, 2));

    } catch (error) {
        console.log(JSON.stringify({ global_error: error.message }));
    } finally {
        await prisma.$disconnect();
    }
}

main();
