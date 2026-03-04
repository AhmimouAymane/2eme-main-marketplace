import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { WalletService } from './wallet.service';
import { AuthGuard } from '@nestjs/passport';
import { GetCurrentUser } from '../../common/decorators/get-current-user.decorator';

@ApiTags('wallet')
@Controller('wallet')
@UseGuards(AuthGuard('jwt'))
@ApiBearerAuth()
export class WalletController {
    constructor(private readonly walletService: WalletService) { }

    @Get('balance')
    @ApiOperation({ summary: 'Get current user wallet balance' })
    getBalance(@GetCurrentUser('sub') userId: string) {
        return this.walletService.getBalance(userId);
    }

    @Get('transactions')
    @ApiOperation({ summary: 'Get wallet transaction history' })
    getTransactions(@GetCurrentUser('sub') userId: string) {
        return this.walletService.getTransactions(userId);
    }
}
