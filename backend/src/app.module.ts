import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { UsersModule } from './modules/users/users.module';
import { AuthModule } from './modules/auth/auth.module';
import { PrismaModule } from './modules/prisma/prisma.module';
import { ProductsModule } from './modules/products/products.module';
import { OrdersModule } from './modules/orders/orders.module';
import { AddressesModule } from './modules/addresses/addresses.module';
import { MediaModule } from './modules/media/media.module';
import { CategoriesModule } from './modules/categories/categories.module';
import { FavoritesModule } from './modules/favorites/favorites.module';
import { ConversationsModule } from './modules/conversations/conversations.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { MailModule } from './modules/mail/mail.module';
import { ConfigModule } from '@nestjs/config';
import { ServeStaticModule } from '@nestjs/serve-static';
import { DashboardModule } from './modules/dashboard/dashboard.module';
import { UserReviewsModule } from './modules/user-reviews/user-reviews.module';
import { SettingsModule } from './modules/settings/settings.module';
import { join } from 'path';
import { ScheduleModule } from '@nestjs/schedule';
import { SellerVerificationModule } from './modules/seller-verification/seller-verification.module';
import { WalletModule } from './modules/wallet/wallet.module';
import { ModerationModule } from './modules/moderation/moderation.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    ScheduleModule.forRoot(),
    UsersModule,
    AuthModule,
    PrismaModule,
    ProductsModule,
    OrdersModule,
    AddressesModule,
    MediaModule,
    CategoriesModule,
    FavoritesModule,
    ConversationsModule,
    NotificationsModule,
    MailModule,
    DashboardModule,
    UserReviewsModule,
    SettingsModule,
    ServeStaticModule.forRoot({
      rootPath: join(__dirname, '..', 'uploads'),
      serveRoot: '/uploads',
    }),
    SellerVerificationModule,
    WalletModule,
    ModerationModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule { }
