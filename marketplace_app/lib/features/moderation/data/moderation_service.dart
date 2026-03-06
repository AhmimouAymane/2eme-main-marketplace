import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/presentation/providers/auth_providers.dart';

enum ReportReason {
  SPAM,
  INAPPROPRIATE_CONTENT,
  FRAUD,
  HARASSMENT,
  OTHER,
}

final moderationServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return ModerationService(dio);
});

class ModerationService {
  final Dio _dio;

  ModerationService(this._dio);

  Future<void> reportContent({
    required ReportReason reason,
    String? description,
    String? reportedUserId,
    String? reportedProductId,
    String? reportedCommentId,
  }) async {
    try {
      await _dio.post('moderation/report', data: {
        'reason': reason.name,
        'description': description,
        'reportedUserId': reportedUserId,
        'reportedProductId': reportedProductId,
        'reportedCommentId': reportedCommentId,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> blockUser(String userId) async {
    try {
      await _dio.post('moderation/block/$userId');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unblockUser(String userId) async {
    try {
      await _dio.delete('moderation/block/$userId');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getBlockedUsers() async {
    try {
      final response = await _dio.get('moderation/blocks');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
