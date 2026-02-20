import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import 'api_interceptor.dart';

/// Client HTTP Dio configuré pour l'API
class ApiClient {
  static Dio? _dio;
  
  static Dio getInstance(Ref ref) {
    _dio ??= _createDio(ref);
    return _dio!;
  }
  
  static Dio _createDio(Ref ref) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    // Ajouter les intercepteurs (avec Ref pour gérer les 401)
    dio.interceptors.add(ApiInterceptor(ref));
    
    // Intercepteur de logs en mode debug
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        requestHeader: true,
        responseHeader: false,
      ),
    );
    
    return dio;
  }
  
  // Réinitialiser le client (utile après déconnexion)
  static void reset() {
    _dio = null;
  }
}
