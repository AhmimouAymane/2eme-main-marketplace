import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../../shared/providers/shop_providers.dart';

final verificationServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return VerificationService(dio);
});

class VerificationService {
  final Dio _dio;

  VerificationService(this._dio);

  Future<void> submitVerification({
    required List<int> idCardFrontBytes,
    required String idCardFrontFileName,
    required List<int> idCardBackBytes,
    required String idCardBackFileName,
    required List<int> bankCertificateBytes,
    required String bankCertificateFileName,
  }) async {
    final formData = FormData.fromMap({
      'idCardFront': MultipartFile.fromBytes(idCardFrontBytes, filename: idCardFrontFileName),
      'idCardBack': MultipartFile.fromBytes(idCardBackBytes, filename: idCardBackFileName),
      'bankCertificate': MultipartFile.fromBytes(
        bankCertificateBytes,
        filename: bankCertificateFileName,
      ),
    });

    await _dio.post('seller-verification/submit', data: formData);
  }

  Future<Map<String, dynamic>> getStatus() async {
    final response = await _dio.get('seller-verification/me');
    return response.data;
  }
}
