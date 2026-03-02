import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_review_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../features/auth/presentation/providers/auth_providers.dart';

final userReviewsServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return UserReviewsService(dio);
});

final topSellersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(userReviewsServiceProvider).getTopSellers();
});

class UserReviewsService {
  final Dio _dio;

  UserReviewsService(this._dio);

  Future<UserReviewModel> createReview({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    final response = await _dio.post('/user-reviews', data: {
      'orderId': orderId,
      'rating': rating,
      if (comment != null) 'comment': comment,
    });
    return UserReviewModel.fromJson(response.data);
  }

  Future<List<UserReviewModel>> getUserReviews(String userId) async {
    final response = await _dio.get('/user-reviews/user/$userId');
    return (response.data as List)
        .map((x) => UserReviewModel.fromJson(x))
        .toList();
  }

  Future<UserReviewModel?> getMyReviewForOrder(String orderId) async {
    try {
      final response = await _dio.get('/user-reviews/order/$orderId/mine');
      if (response.data == null || response.data == '') return null;
      return UserReviewModel.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getTopSellers() async {
    final response = await _dio.get('/user-reviews/top-sellers');
    return (response.data as List).cast<Map<String, dynamic>>();
  }
}
