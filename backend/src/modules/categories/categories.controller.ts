import { Controller, Get } from '@nestjs/common';
import { CategoriesService } from './categories.service';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';

@ApiTags('Categories')
@Controller('categories')
export class CategoriesController {
    constructor(private readonly categoriesService: CategoriesService) { }

    @Get()
    @ApiOperation({ summary: 'Get full category hierarchy' })
    @ApiResponse({ status: 200, description: 'Return all categories as a tree.' })
    findAll() {
        return this.categoriesService.findAll();
    }
}
