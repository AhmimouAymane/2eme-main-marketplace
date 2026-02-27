const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log('--- DATABASE DIAGNOSTICS ---');

    try {
        const schemas = ['public', 'strapi'];

        for (const schema of schemas) {
            console.log(`\nSchema: ${schema}`);
            const tables = await prisma.$queryRawUnsafe(`
        SELECT table_name, table_type 
        FROM information_schema.tables 
        WHERE table_schema = '${schema}'
        ORDER BY table_name;
      `);
            console.table(tables);

            if (schema === 'public') {
                const counts = await prisma.$queryRawUnsafe(`
          SELECT 
            (SELECT COUNT(*) FROM public.users) as user_count,
            (SELECT COUNT(*) FROM public.products) as product_count
        `);
                console.log('Record counts (public):', counts);
            }

            if (schema === 'strapi') {
                const products = await prisma.$queryRawUnsafe(`
          SELECT COUNT(*) as count FROM strapi.products
        `).catch(e => [{ count: 'ERROR' }]);
                console.log('Record counts (strapi.products):', products);
            }
        }

        console.log('\n--- INDEXES (CONFLICT CHECK) ---');
        const indexes = await prisma.$queryRawUnsafe(`
      SELECT tablename, indexname, indexdef 
      FROM pg_indexes 
      WHERE schemaname = 'public' 
      AND (tablename = 'categories' OR tablename = 'products')
    `);
        console.table(indexes);

    } catch (error) {
        console.error('Diagnostic failed:', error);
    } finally {
        await prisma.$disconnect();
    }
}

main();
