import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Category } from '@prisma/client';

export interface CategoryTree extends Category {
    children?: CategoryTree[];
}

@Injectable()
export class CategoriesService {
    constructor(private prisma: PrismaService) { }

    async findAll(): Promise<CategoryTree[]> {
        // Fetch all categories
        const categories = await this.prisma.category.findMany({
            orderBy: { name: 'asc' },
        });

        // Build tree structure
        const genre = categories.filter(c => c.level === 0);

        const buildTree = (parents: any[]): CategoryTree[] => {
            return parents.map(parent => {
                const children = categories.filter(c => c.parentId === parent.id);
                if (children.length > 0) {
                    return {
                        ...parent,
                        children: buildTree(children),
                    };
                }
                return parent;
            });
        };

        return buildTree(genre);
    }

    async findFlat() {
        return this.prisma.category.findMany({
            orderBy: [{ level: 'asc' }, { name: 'asc' }],
        });
    }

    async create(data: { name: string; slug: string; level: number; parentId?: string; possibleSizes?: string[] }) {
        return this.prisma.category.create({
            data: {
                ...data,
                possibleSizes: data.possibleSizes || [],
            },
        });
    }

    async update(id: string, data: { name?: string; slug?: string; level?: number; parentId?: string; possibleSizes?: string[] }) {
        return this.prisma.category.update({
            where: { id },
            data,
        });
    }

    async remove(id: string) {
        return this.prisma.category.delete({
            where: { id },
        });
    }
}
