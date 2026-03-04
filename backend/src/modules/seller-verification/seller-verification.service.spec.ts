import { Test, TestingModule } from '@nestjs/testing';
import { SellerVerificationService } from './seller-verification.service';

describe('SellerVerificationService', () => {
  let service: SellerVerificationService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [SellerVerificationService],
    }).compile();

    service = module.get<SellerVerificationService>(SellerVerificationService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
