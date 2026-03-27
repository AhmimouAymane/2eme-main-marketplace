import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_review_model.dart';
import '../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../shared/services/cache_service.dart';
import '../../../shared/providers/cache_providers.dart';

final userReviewsServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  final cache = ref.watch(cacheServiceProvider);
  return UserReviewsService(dio, cache);
});

final topSellersProvider = AsyncNotifierProvider<TopSellersNotifier, List<Map<String, dynamic>>>(() {
  return TopSellersNotifier();
});

class TopSellersNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  FutureOr<List<Map<String, dynamic>>> build() {
    final service = ref.watch(userReviewsServiceProvider);
    
    // 1. Retourner le cache immédiatement
    final cached = service.getCachedTopSellers();
    
    // 2. Lancer la mise à jour en arrière-plan
    _fetchTopSellers();
    
    return cached;
  }

  Future<void> _fetchTopSellers() async {
    try {
      final service = ref.read(userReviewsServiceProvider);
      final sellers = await service.getTopSellers();
      
      // Mettre à jour le cache
      await service.cacheTopSellers(sellers);
      
      // Mettre à jour l'état
      state = AsyncData(sellers);
    } catch (e, stack) {
      print('TopSellersNotifier error: $e');
      if (!state.hasValue || state.value!.isEmpty) {
        state = AsyncError(e, stack);
      }
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await _fetchTopSellers();
  }
}

final myReviewForOrderProvider = FutureProvider.autoDispose.family<UserReviewModel?, String>((ref, orderId) async {
  return ref.watch(userReviewsServiceProvider).getMyReviewForOrder(orderId);
});

class UserReviewsService {
  final Dio _dio;
  final CacheService _cache;
  static const String topSellersCacheKey = 'cached_top_sellers';

  UserReviewsService(this._dio, this._cache);

  List<Map<String, dynamic>> getCachedTopSellers() {
    return _cache.getList(topSellersCacheKey, (json) => json.cast<String, dynamic>());
  }

  Future<void> cacheTopSellers(List<Map<String, dynamic>> sellers) async {
    await _cache.saveList(topSellersCacheKey, sellers);
  }

  Future<UserReviewModel> createReview({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    final response = await _dio.post('user-reviews', data: {
      'orderId': orderId,
      'rating': rating,
      if (comment != null) 'comment': comment,
    });
    return UserReviewModel.fromJson(response.data);
  }

  Future<List<UserReviewModel>> getUserReviews(String userId) async {
    final response = await _dio.get('user-reviews/user/$userId');
    return (response.data as List)
        .map((x) => UserReviewModel.fromJson(x))
        .toList();
  }

  Future<UserReviewModel?> getMyReviewForOrder(String orderId) async {
    try {
      final response = await _dio.get('user-reviews/order/$orderId/mine');
      if (response.data == null || response.data == '') return null;
      return UserReviewModel.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getTopSellers() async {
    final response = await _dio.get('user-reviews/top-sellers');
    return (response.data as List).cast<Map<String, dynamic>>();
  }
}
