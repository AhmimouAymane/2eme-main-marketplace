import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marketplace_app/core/constants/app_constants.dart';
import 'package:marketplace_app/shared/services/api_client.dart';

/// Service gérant l'authentification côté frontend
class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  /// Inscription d'un nouvel utilisateur
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      });
      
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Connexion de l'utilisateur
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      final data = response.data;
      final token = data['accessToken'];
      final user = data['user'];
      
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.keyAuthToken, token);
        if (user != null) {
          await prefs.setString(AppConstants.keyUserId, user['id']);
          await prefs.setString(AppConstants.keyUserEmail, user['email']);
        }
      }
      
      return data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAuthToken);
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyUserEmail);
    ApiClient.reset();
  }

  /// Vérifier si l'utilisateur est connecté
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyAuthToken);
    return token != null && token.isNotEmpty;
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final message = e.response?.data['message'];
      if (message is List) return message.join(', ');
      return message ?? 'Une erreur est survenue';
    }
    return 'Impossible de contacter le serveur';
  }
}
