import { Controller, Get, Post, Patch, Delete, Param, Body, UseGuards, Req, Put } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AddressesService } from './addresses.service';
import { CreateAddressDto } from './dto/create-address.dto';
import { UpdateAddressDto } from './dto/update-address.dto';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';

@ApiTags('addresses')
@ApiBearerAuth()
@Controller('users/:userId/addresses')
@UseGuards(AuthGuard('jwt'))
export class AddressesController {
  constructor(private readonly addressesService: AddressesService) {}

  @Get()
  async findAll(@Param('userId') userId: string) {
    return this.addressesService.findAll(userId);
  }

  @Post()
  async create(
    @Param('userId') userId: string,
    @Body() dto: CreateAddressDto,
  ) {
    return this.addressesService.create(userId, dto);
  }

  @Get(':id')
  async findOne(@Param('userId') userId: string, @Param('id') id: string) {
    return this.addressesService.findOne(id, userId);
  }

  @Patch(':id')
  async update(
    @Param('userId') userId: string,
    @Param('id') id: string,
    @Body() dto: UpdateAddressDto,
  ) {
    return this.addressesService.update(id, userId, dto);
  }

  @Delete(':id')
  async remove(@Param('userId') userId: string, @Param('id') id: string) {
    return this.addressesService.remove(id, userId);
  }

  @Put(':id/default')
  async setDefault(@Param('userId') userId: string, @Param('id') id: string) {
    await this.addressesService.setDefault(userId, id);
    return { success: true };
  }
}
