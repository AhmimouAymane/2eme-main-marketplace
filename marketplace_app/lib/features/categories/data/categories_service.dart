import 'package:dio/dio.dart';
import 'package:marketplace_app/shared/models/category_model.dart';

/// Service pour gérer les appels API liés aux catégories
class CategoriesService {
  final Dio _dio;

  CategoriesService(this._dio);

  /// Récupérer la hiérarchie complète des catégories
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _dio.get('/categories');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
