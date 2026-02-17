import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateAddressDto } from './dto/create-address.dto';
import { UpdateAddressDto } from './dto/update-address.dto';
import { Address } from '@prisma/client';

@Injectable()
export class AddressesService {
  constructor(private prisma: PrismaService) {}

  async findAll(userId: string): Promise<Address[]> {
    return this.prisma.address.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(id: string, userId: string): Promise<Address> {
    const addr = await this.prisma.address.findUnique({
      where: { id },
    });
    if (!addr || addr.userId !== userId) {
      throw new NotFoundException(`Address not found`);
    }
    return addr;
  }

  async create(userId: string, dto: CreateAddressDto): Promise<Address> {
    // if this is first address or dto indicates default, update others
    const count = await this.prisma.address.count({ where: { userId } });
    const isDefault = count == 0;

    const addr = await this.prisma.address.create({
      data: {
        userId,
        ...dto,
        isDefault,
      },
    });

    return addr;
  }

  async update(id: string, userId: string, dto: UpdateAddressDto): Promise<Address> {
    const addr = await this.findOne(id, userId);

    // if updating isDefault to true, unset others
    if (dto.isDefault === true) {
      await this.prisma.address.updateMany({
        where: { userId, id: { not: id } },
        data: { isDefault: false },
      });
    }

    return this.prisma.address.update({
      where: { id },
      data: {
        label: dto.label,
        street: dto.street,
        city: dto.city,
        postal: dto.postal,
        country: dto.country,
        isDefault: dto.isDefault,
      },
    });
  }

  async remove(id: string, userId: string): Promise<void> {
    const addr = await this.findOne(id, userId);
    await this.prisma.address.delete({ where: { id } });

    // if deleted default, optionally set another default
    if (addr.isDefault) {
      const other = await this.prisma.address.findFirst({ where: { userId } });
      if (other) {
        await this.prisma.address.update({
          where: { id: other.id },
          data: { isDefault: true },
        });
      }
    }
  }

  async setDefault(userId: string, id: string): Promise<void> {
    await this.prisma.address.updateMany({
      where: { userId },
      data: { isDefault: false },
    });
    await this.prisma.address.update({
      where: { id },
      data: { isDefault: true },
    });
  }
}
