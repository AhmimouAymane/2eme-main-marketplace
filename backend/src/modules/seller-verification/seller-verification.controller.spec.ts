import { Test, TestingModule } from '@nestjs/testing';
import { SellerVerificationController } from './seller-verification.controller';

describe('SellerVerificationController', () => {
  let controller: SellerVerificationController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [SellerVerificationController],
    }).compile();

    controller = module.get<SellerVerificationController>(SellerVerificationController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
