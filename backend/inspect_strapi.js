const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    try {
        console.log('--- STRAPI 5 SCHEMA INSPECTION ---');

        // Check columns of products table in strapi schema
        const columns = await prisma.$queryRawUnsafe(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns 
      WHERE table_schema = 'strapi' 
      AND table_name = 'products'
      ORDER BY ordinal_position;
    `);
        console.log('Columns in strapi.products:');
        console.table(columns);

        // Check if there are any records in strapi.products (even if I made it a view)
        const count = await prisma.$queryRawUnsafe('SELECT COUNT(*) as count FROM strapi.products').catch(e => [{ count: 'ERROR' }]);
        console.log('Record count in strapi.products:', count);

        // Check relationship tables created by Strapi
        const relTables = await prisma.$queryRawUnsafe(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'strapi' 
      AND table_name LIKE '%lnk%'
    `);
        console.log('Relationship (link) tables found:');
        console.table(relTables);

    } catch (error) {
        console.error('Inspection failed:', error);
    } finally {
        await prisma.$disconnect();
    }
}

main();
