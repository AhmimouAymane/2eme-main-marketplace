import 'package:dio/dio.dart';
import 'package:marketplace_app/shared/models/user_model.dart';

class UsersService {
  final Dio _dio;

  UsersService(this._dio);

  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get('/users/me');
      return UserModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/users/me', data: data);
      return UserModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> getPublicProfile(String userId) async {
    try {
      final response = await _dio.get('/users/$userId');
      return UserModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
