import 'package:dio/dio.dart';
import 'package:marketplace_app/shared/models/product_model.dart';

class FavoritesService {
  final Dio _dio;

  FavoritesService(this._dio);

  Future<bool> toggleFavorite(String productId) async {
    try {
      final response = await _dio.post('/favorites/$productId');
      if (response.statusCode == 201) {
        return response.data['favorited'] as bool;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ProductModel>> getFavorites() async {
    try {
      final response = await _dio.get('/favorites');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ProductModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
