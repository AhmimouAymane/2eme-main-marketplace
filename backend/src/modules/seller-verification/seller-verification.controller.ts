import {
    Controller,
    Get,
    Post,
    Body,
    Patch,
    Param,
    UseGuards,
    UseInterceptors,
    UploadedFiles,
    Res,
    Query,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiResponse, ApiConsumes, ApiBody } from '@nestjs/swagger';
import { FileFieldsInterceptor } from '@nestjs/platform-express';
import * as express from 'express';
import { SellerVerificationService } from './seller-verification.service';
import { RejectVerificationDto } from './dto/seller-verification.dto';
import { AuthGuard } from '@nestjs/passport';
import { GetCurrentUser } from '../../common/decorators/get-current-user.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@ApiTags('seller-verification')
@Controller('seller-verification')
@UseGuards(AuthGuard('jwt'))
@ApiBearerAuth()
export class SellerVerificationController {
    constructor(private readonly verificationService: SellerVerificationService) { }

    @Post('submit')
    @UseInterceptors(FileFieldsInterceptor([
        { name: 'idCardFront', maxCount: 1 },
        { name: 'idCardBack', maxCount: 1 },
        { name: 'bankCertificate', maxCount: 1 },
    ]))
    @ApiConsumes('multipart/form-data')
    @ApiBody({
        schema: {
            type: 'object',
            properties: {
                idCardFront: { type: 'string', format: 'binary' },
                idCardBack: { type: 'string', format: 'binary' },
                bankCertificate: { type: 'string', format: 'binary' },
            },
        },
    })
    @ApiOperation({ summary: 'Submit documents for seller verification' })
    submit(
        @UploadedFiles() files: {
            idCardFront?: any[];
            idCardBack?: any[];
            bankCertificate?: any[]
        },
        @GetCurrentUser('sub') userId: string,
    ) {
        return this.verificationService.submitVerification(userId, {
            idCardFront: files.idCardFront?.[0],
            idCardBack: files.idCardBack?.[0],
            bankCertificate: files.bankCertificate?.[0],
        });
    }

    @Get('me')
    @ApiOperation({ summary: 'Get current user verification status' })
    getMe(@GetCurrentUser('sub') userId: string) {
        return this.verificationService.getStatus(userId);
    }

    @Get('list')
    @UseGuards(RolesGuard)
    @Roles(Role.ADMIN)
    @ApiOperation({ summary: 'List verification requests by status (Admin only)' })
    findAllByStatus(@Query('status') status: string) {
        console.log(`[Admin] Fetching verifications for status: ${status}`);
        return this.verificationService.findAllByStatus(status as any);
    }

    @Get('pending')
    @UseGuards(RolesGuard)
    @Roles(Role.ADMIN)
    @ApiOperation({ summary: 'List all pending verification requests (Admin only)' })
    findAllPending() {
        return this.verificationService.findAllPending();
    }

    @Patch(':id/approve')
    @UseGuards(RolesGuard)
    @Roles(Role.ADMIN)
    @ApiOperation({ summary: 'Approve seller verification (Admin only)' })
    approve(@Param('id') userId: string) {
        return this.verificationService.approve(userId);
    }

    @Patch(':id/reject')
    @UseGuards(RolesGuard)
    @Roles(Role.ADMIN)
    @ApiOperation({ summary: 'Reject seller verification (Admin only)' })
    reject(
        @Param('id') userId: string,
        @Body() dto: RejectVerificationDto,
    ) {
        return this.verificationService.reject(userId, dto.comment);
    }

    @Get('document/:docId')
    @UseGuards(RolesGuard)
    @Roles(Role.ADMIN)
    @ApiOperation({ summary: 'Get secure document content (Admin only)' })
    async getDocument(
        @Param('docId') docId: string,
        @Res() res: express.Response,
    ) {
        const doc = await this.verificationService.getDocument(docId);
        res.setHeader('Content-Type', doc.mimeType);
        res.setHeader('Content-Disposition', `inline; filename="${doc.fileName}"`);
        return res.send(doc.fileData);
    }
}
