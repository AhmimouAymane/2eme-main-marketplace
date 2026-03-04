import { Module } from '@nestjs/common';
import { SellerVerificationService } from './seller-verification.service';
import { SellerVerificationController } from './seller-verification.controller';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [NotificationsModule],
  providers: [SellerVerificationService],
  controllers: [SellerVerificationController]
})
export class SellerVerificationModule { }
