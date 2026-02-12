import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateUserDto } from './dto/create-user.dto';
import { User, Prisma } from '@prisma/client';

@Injectable()
export class UsersService {
    constructor(private prisma: PrismaService) { }

    async findOne(id: string, includeProducts = false): Promise<User | null> {
        return this.prisma.user.findUnique({
            where: { id },
            include: {
                products: includeProducts ? {
                    include: {
                        images: true,
                        category: true,
                    },
                    orderBy: {
                        createdAt: 'desc',
                    },
                } : false,
            },
        });
    }

    async findByEmail(email: string): Promise<User | null> {
        return this.prisma.user.findUnique({
            where: { email },
        });
    }

    async create(data: CreateUserDto): Promise<User> {
        return this.prisma.user.create({
            data: {
                ...data,
                role: 'USER',
            },
        });
    }

    async update(id: string, data: Prisma.UserUpdateInput): Promise<User> {
        return this.prisma.user.update({
            where: { id },
            data,
        });
    }

    async remove(id: string): Promise<User> {
        return this.prisma.user.delete({
            where: { id },
        });
    }
}
