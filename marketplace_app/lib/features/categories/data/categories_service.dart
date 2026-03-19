import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marketplace_app/shared/models/category_model.dart';

/// Service pour gérer les appels API liés aux catégories
class CategoriesService {
  final Dio _dio;
  static const String _categoriesCacheKey = 'cached_categories';

  CategoriesService(this._dio);

  /// Récupérer la hiérarchie complète des catégories (avec cache local)
  Future<List<CategoryModel>> getCategories({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Essayer de retourner le cache immédiat si on ne force pas le rafraîchissement
    if (!forceRefresh) {
      final cachedData = prefs.getString(_categoriesCacheKey);
      if (cachedData != null && cachedData.isNotEmpty) {
        try {
          final List<dynamic> decodedData = jsonDecode(cachedData);
          final categories = decodedData.map((json) => CategoryModel.fromJson(json)).toList();
          
          // Lancer la mise à jour en arrière-plan silencieusement
          _fetchAndCacheCategories(prefs).catchError((e) => print('Background category update failed: $e'));
          
          return categories; // Retour immédiat du cache
        } catch (e) {
          print('Error decoding categories cache: $e');
        }
      }
    }

    // 2. Pas de cache ou forceRefresh=true : on attend l'appel API
    return _fetchAndCacheCategories(prefs);
  }

  /// Appelle l'API et met en cache la réponse brute
  Future<List<CategoryModel>> _fetchAndCacheCategories(SharedPreferences prefs) async {
    try {
      final response = await _dio.get('categories');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        
        // Sauvegarder dans le cache sous forme de string JSON
        await prefs.setString(_categoriesCacheKey, jsonEncode(data));

        return data.map((json) => CategoryModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      // En cas d'erreur de réseau, on essaie au moins de retourner le cache s'il en reste un
      final cachedData = prefs.getString(_categoriesCacheKey);
      if (cachedData != null) {
        try {
          final List<dynamic> decodedData = jsonDecode(cachedData);
          return decodedData.map((json) => CategoryModel.fromJson(json)).toList();
        } catch (_) {}
      }
      rethrow;
    }
  }
}
