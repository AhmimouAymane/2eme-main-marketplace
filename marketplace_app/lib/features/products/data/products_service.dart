import 'package:dio/dio.dart';
import 'package:marketplace_app/shared/models/product_model.dart';
import 'package:marketplace_app/shared/services/api_client.dart';

/// Service pour gérer les appels API liés aux produits
class ProductsService {
  final Dio _dio;

  ProductsService(this._dio);

  /// Récupérer tous les produits avec filtres optionnels
  Future<List<ProductModel>> getProducts({
    String? search,
    String? category,
    String? condition,
    String? status,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? order,
    String? sellerId,
  }) async {
    try {
      final queryParams = {
        'search': search,
        'categoryId': category,
        'condition': condition,
        'status': status,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'sortBy': sortBy,
        'order': order,
        'sellerId': sellerId,
      };
      
      queryParams.removeWhere((key, value) => value == null);
      
      print('ProductsService.getProducts: queryParams=$queryParams');

      final response = await _dio.get('/products', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ProductModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Récupérer un produit par son ID
  Future<ProductModel> getProduct(String id) async {
    try {
      final response = await _dio.get('/products/$id');
      if (response.statusCode == 200) {
        return ProductModel.fromJson(response.data);
      }
      throw Exception('Failed to load product');
    } catch (e) {
      rethrow;
    }
  }

  /// Créer un nouveau produit
  Future<ProductModel> createProduct(ProductModel product) async {
    try {
      final response = await _dio.post(
        '/products',
        data: product.toJson(),
      );
      if (response.statusCode == 201) {
        return ProductModel.fromJson(response.data);
      }
      throw Exception('Failed to create product');
    } catch (e) {
      rethrow;
    }
  }

  /// Mettre à jour un produit
  Future<ProductModel> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(
        '/products/$id',
        data: data,
      );
      if (response.statusCode == 200) {
        return ProductModel.fromJson(response.data);
      }
      throw Exception('Failed to update product');
    } catch (e) {
      rethrow;
    }
  }

  /// Supprimer un produit
  Future<void> deleteProduct(String id) async {
    try {
      final response = await _dio.delete('/products/$id');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete product');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Ajouter une évaluation
  Future<void> addReview(String productId, int rating, String? comment) async {
    try {
      await _dio.post('/products/$productId/reviews', data: {
        'rating': rating,
        'comment': ?comment,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Ajouter un commentaire
  Future<void> addComment(String productId, String content) async {
    try {
      await _dio.post('/products/$productId/comments', data: {
        'content': content,
      });
    } catch (e) {
      rethrow;
    }
  }
}
