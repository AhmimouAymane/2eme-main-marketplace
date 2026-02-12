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
}
