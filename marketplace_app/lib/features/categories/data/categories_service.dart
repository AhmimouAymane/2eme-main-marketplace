import 'package:dio/dio.dart';
import 'package:marketplace_app/shared/models/category_model.dart';
import 'package:marketplace_app/shared/services/cache_service.dart';

/// Service pour gérer les appels API liés aux catégories
class CategoriesService {
  final Dio _dio;
  final CacheService _cache;
  static const String _categoriesCacheKey = 'cached_categories';

  CategoriesService(this._dio, this._cache);

  /// Récupérer la hiérarchie complète des catégories (avec cache local)
  Future<List<CategoryModel>> getCategories({bool forceRefresh = false}) async {
    // 1. Retourner le cache immédiat si disponible
    if (!forceRefresh) {
      final cached = _cache.getList(_categoriesCacheKey, (json) => CategoryModel.fromJson(json));
      if (cached.isNotEmpty) {
        // Mise à jour en arrière-plan
        _fetchAndCacheCategories().catchError((e) => print('Background category update failed: $e'));
        return cached;
      }
    }

    // 2. Pas de cache ou forceRefresh=true
    return _fetchAndCacheCategories();
  }

  /// Appelle l'API et met en cache la réponse brute
  Future<List<CategoryModel>> _fetchAndCacheCategories() async {
    try {
      final response = await _dio.get('categories');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        await _cache.saveList(_categoriesCacheKey, data);
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      // Fallback sur le cache en cas d'erreur
      final cached = _cache.getList(_categoriesCacheKey, (json) => CategoryModel.fromJson(json));
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }
}
