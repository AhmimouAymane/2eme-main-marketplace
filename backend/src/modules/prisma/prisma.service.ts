import { Injectable, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
    async onModuleInit() {
        await this.$connect();
    }

    // enableShutdownHooks is deprecated in Prisma 5+ and handled differently or not needed
    // async enableShutdownHooks(app: any) { ... }
}
