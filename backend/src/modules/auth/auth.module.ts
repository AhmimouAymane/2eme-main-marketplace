import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { UsersModule } from '../users/users.module';
import { AtStrategy } from './strategies/at.strategy';
import { FirebaseModule } from '../firebase/firebase.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    UsersModule,
    PassportModule,
    JwtModule.register({}),
    FirebaseModule,
    NotificationsModule,
  ],
  controllers: [AuthController],
  providers: [AuthService, AtStrategy],
})
export class AuthModule { }
