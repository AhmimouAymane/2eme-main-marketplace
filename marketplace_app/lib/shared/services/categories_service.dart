import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_app/core/constants/app_constants.dart';
import 'package:marketplace_app/shared/models/category_model.dart';
// Assuming dioProvider is here or I can use Dio directly if simple

// Simple provider for CategoriesService
final categoriesServiceProvider = Provider<CategoriesService>((ref) {
  return CategoriesService();
});

// Future provider to fetch the tree once
final categoriesTreeProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final service = ref.watch(categoriesServiceProvider);
  return service.getCategoriesTree();
});

class CategoriesService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));

  Future<List<CategoryModel>> getCategoriesTree() async {
    try {
      final response = await _dio.get('/categories');
      final List<dynamic> data = response.data;
      return data.map((json) => CategoryModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching categories: $e');
      throw Exception('Failed to load categories');
    }
  }
}
