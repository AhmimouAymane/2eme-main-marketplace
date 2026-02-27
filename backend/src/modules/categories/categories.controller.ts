import { Controller, Get, Post, Body, Patch, Param, Delete, Res, Query, UseGuards } from '@nestjs/common';
import type { Response } from 'express';
import { CategoriesService } from './categories.service';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@ApiTags('Categories')
@Controller('categories')
export class CategoriesController {
    constructor(private readonly categoriesService: CategoriesService) { }

    @Get()
    @ApiOperation({ summary: 'Get category hierarchy or flat list' })
    @ApiResponse({ status: 200, description: 'Return categories.' })
    async findAll(
        @Res() res: Response,
        @Query('flat') flat?: string,
        @Query('_start') start?: string,
        @Query('_end') end?: string,
        @Query('_sort') sort?: string,
        @Query('_order') order?: string,
    ) {
        let categories;
        // If 'flat' is explicitly requested OR if pagination/sorting params are present (likely Refine)
        if (flat === 'true' || start !== undefined || sort !== undefined) {
            categories = await this.categoriesService.findFlat();

            // Basic filtering/sorting for Refine if needed
            if (sort) {
                const dir = order?.toLowerCase() === 'desc' ? -1 : 1;
                categories.sort((a: any, b: any) => (a[sort] > b[sort] ? 1 : -1) * dir);
            }

            if (start !== undefined && end !== undefined) {
                const total = categories.length;
                categories = categories.slice(Number(start), Number(end));
                res.setHeader('X-Total-Count', total);
            } else {
                res.setHeader('X-Total-Count', categories.length);
            }
        } else {
            categories = await this.categoriesService.findAll();
            res.setHeader('X-Total-Count', categories.length);
        }

        res.setHeader('Access-Control-Expose-Headers', 'X-Total-Count');
        return res.json(categories);
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get category by id' })
    async findOne(@Param('id') id: string) {
        return (await this.categoriesService.findFlat()).find(c => c.id === id);
    }

    @Post()
    @UseGuards(AuthGuard('jwt'), RolesGuard)
    @Roles(Role.ADMIN)
    @ApiBearerAuth()
    @ApiOperation({ summary: 'Create category (Admin only)' })
    create(@Body() data: any) {
        return this.categoriesService.create(data);
    }

    @Patch(':id')
    @UseGuards(AuthGuard('jwt'), RolesGuard)
    @Roles(Role.ADMIN)
    @ApiBearerAuth()
    @ApiOperation({ summary: 'Update category (Admin only)' })
    update(@Param('id') id: string, @Body() data: any) {
        return this.categoriesService.update(id, data);
    }

    @Delete(':id')
    @UseGuards(AuthGuard('jwt'), RolesGuard)
    @Roles(Role.ADMIN)
    @ApiBearerAuth()
    @ApiOperation({ summary: 'Delete category (Admin only)' })
    remove(@Param('id') id: string) {
        return this.categoriesService.remove(id);
    }
}
