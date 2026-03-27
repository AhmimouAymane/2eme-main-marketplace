import 'package:dio/dio.dart';
import 'package:marketplace_app/shared/models/user_model.dart';
import 'package:marketplace_app/shared/services/cache_service.dart';

class UsersService {
  final Dio _dio;
  final CacheService _cache;
  static const String profileCacheKey = 'cached_user_profile';

  UsersService(this._dio, this._cache);

  /// Récupère le profil mis en cache
  UserModel? getCachedProfile() {
    final list = _cache.getList(profileCacheKey, (json) => UserModel.fromJson(json));
    return list.isNotEmpty ? list.first : null;
  }

  /// Sauvegarde le profil en cache (on utilise une liste d'un seul élément pour CacheService)
  Future<void> cacheProfile(UserModel user) async {
    await _cache.saveList(profileCacheKey, [user.toJson()]);
  }

  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get('users/me');
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
      final response = await _dio.patch('users/me', data: data);
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
      final response = await _dio.get('users/$userId');
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
        'users/$targetUserId/reviews',
        data: {'rating': rating, 'comment': comment},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Supprimer le compte (DB + Firebase)
  Future<void> deleteAccount() async {
    try {
      await _dio.delete('users/me');
    } catch (e) {
      rethrow;
    }
  }

  /// Rechercher des utilisateurs par nom/prénom
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await _dio.get('users/search', queryParameters: {'q': query});
      final data = response.data;
      if (data is List) {
        return data.map((u) => UserModel.fromJson(u)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
