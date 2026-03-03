import { Injectable, OnModuleInit } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateSettingsDto } from './dto/update-settings.dto';

@Injectable()
export class SettingsService implements OnModuleInit {
    constructor(private prisma: PrismaService) { }

    async onModuleInit() {
        // Initialize default settings if they don't exist
        const settings = await this.prisma.systemSettings.findUnique({
            where: { id: 'default' },
        });

        if (!settings) {
            await this.prisma.systemSettings.create({
                data: {
                    id: 'default',
                    serviceFeePercentage: 5.0,
                    shippingFee: 25.0,
                },
            });
        }
    }

    async getSettings() {
        return this.prisma.systemSettings.findUnique({
            where: { id: 'default' },
        });
    }

    async updateSettings(dto: UpdateSettingsDto) {
        return this.prisma.systemSettings.update({
            where: { id: 'default' },
            data: dto,
        });
    }
}
