import 'package:dio/dio.dart';
import 'package:marketplace_app/shared/models/user_model.dart';

class UsersService {
  final Dio _dio;

  UsersService(this._dio);

  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get('/users/me');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return UserModel.fromJson(data);
      }
      // Backend peut renvoyer une chaîne simple en cas d'erreur
      throw Exception(data.toString());
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/users/me', data: data);
      final body = response.data;
      if (body is Map<String, dynamic>) {
        return UserModel.fromJson(body);
      }
      throw Exception(body.toString());
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> getPublicProfile(String userId) async {
    try {
      final response = await _dio.get('/users/$userId');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return UserModel.fromJson(data);
      }
      throw Exception(data.toString());
    } catch (e) {
      rethrow;
    }
  }

  /// Évaluer un utilisateur (vendeur)
  Future<void> rateUser(
    String targetUserId,
    int rating,
    String? comment,
  ) async {
    try {
      await _dio.post(
        '/users/$targetUserId/reviews',
        data: {'rating': rating, 'comment': comment},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Supprimer le compte (DB + Firebase)
  Future<void> deleteAccount() async {
    try {
      await _dio.delete('/users/me');
    } catch (e) {
      rethrow;
    }
  }
}
