import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { UsersService } from './users.service';

@Injectable()
export class UserCleanupService {
  private readonly logger = new Logger(UserCleanupService.name);

  constructor(private readonly usersService: UsersService) {}

  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
  async handleCleanup() {
    this.logger.log('Starting daily cleanup of deleted users...');
    try {
      const count = await this.usersService.anonymizeDeletedUsers();
      this.logger.log(`Cleanup completed. ${count} users anonymized.`);
    } catch (error) {
      this.logger.error('Failed to anonymize deleted users:', error);
    }
  }
}
