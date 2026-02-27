import { Module } from '@nestjs/common';
import { OrdersService } from './orders.service';
import { OrdersController } from './orders.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { OrderExpirationService } from './order-expiration.service';

@Module({
    imports: [PrismaModule, NotificationsModule],
    controllers: [OrdersController],
    providers: [OrdersService, OrderExpirationService],
    exports: [OrdersService],
})
export class OrdersModule { }
